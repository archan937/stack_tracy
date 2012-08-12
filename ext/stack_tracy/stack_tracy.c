#include "stack_tracy.h"

static double nsec() {
  #if defined(__linux__)
    struct timespec clock;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &clock);
    return (clock.tv_sec * 1000000000 + clock.tv_nsec) / 1000000000.0;
  #elif defined(_win32)
    FILETIME createTime;
    FILETIME exitTime;
    FILETIME sysTime;
    FILETIME cpuTime;

    ULARGE_INTEGER sysTimeInt;
    ULARGE_INTEGER cpuTimeInt;
    ULONGLONG totalTime;

    GetProcessTimes(GetCurrentProcess(), &createTime, &exitTime, &sysTime, &cpuTime);

    /* Doing this based on MSFT's recommendation in the FILETIME structure documentation at
      http://msdn.microsoft.com/en-us/library/ms724284%28VS.85%29.aspx*/

    sysTimeInt.LowPart = sysTime.dwLowDateTime;
    sysTimeInt.HighPart = sysTime.dwHighDateTime;
    cpuTimeInt.LowPart = cpuTime.dwLowDateTime;
    cpuTimeInt.HighPart = cpuTime.dwHighDateTime;

    totalTime = sysTimeInt.QuadPart + cpuTimeInt.QuadPart;

    // Times are in 100-nanosecond time units.  So instead of 10-9 use 10-7
    return totalTime / 10000000.0;
  #else
    return ((double) clock()) / CLOCKS_PER_SEC;
  #endif
}

static const char *event_name(rb_event_flag_t event) {
  switch (event) {
    case RUBY_EVENT_LINE:
  return "line";
    case RUBY_EVENT_CLASS:
  return "class";
    case RUBY_EVENT_END:
  return "end";
    case RUBY_EVENT_CALL:
  return "call";
    case RUBY_EVENT_RETURN:
  return "return";
    case RUBY_EVENT_C_CALL:
  return "c-call";
    case RUBY_EVENT_C_RETURN:
  return "c-return";
    case RUBY_EVENT_RAISE:
  return "raise";
  #ifdef RUBY_VM
    case RUBY_EVENT_SWITCH:
  return "thread-interrupt";
  #endif
    default:
  return "unknown";
  }
}

#if defined(RB_EVENT_HOOKS_HAVE_CALLBACK_DATA) || defined(RUBY_EVENT_VM)
static void stack_tracy_trap(rb_event_flag_t event, VALUE data, VALUE self, ID id, VALUE klass)
#else
static void stack_tracy_trap(rb_event_flag_t event, NODE *node, VALUE self, ID id, VALUE klass)
#endif
{
  bool singleton = false;
  EventInfo info;

  if (event == RUBY_EVENT_CALL || event == RUBY_EVENT_C_CALL) {
    trace = true;
  }

  if (trace == false) {
    return;
  }

  #ifdef RUBY_VM
  if (id == 0) {
    rb_frame_method_id_and_class(&id, &klass);
  }
  #endif

  if (klass) {
    if (TYPE(klass) == T_ICLASS) {
      klass = RBASIC(klass)->klass;
    }

    singleton = FL_TEST(klass, FL_SINGLETON);

    #ifdef RUBY_VM
    if (singleton && !(TYPE(self) == T_CLASS || TYPE(self) == T_MODULE))
      singleton = false;
    #endif
  }

  if ((ID *) id != NULL) {
    info.event = event;
    info.file = (char *) rb_sourcefile();
    info.line = rb_sourceline();
    info.singleton = singleton;
    info.object = (VALUE *)(singleton ? self : klass);
    info.method = (ID *)id;
    info.nsec = nsec();

    size = size + 1;
    stack = (EventInfo *) realloc (stack, size * sizeof(EventInfo));
    stack[size - 1] = info;
  }
}

VALUE stack_tracy_start(VALUE self) {
  #if defined(RB_EVENT_HOOKS_HAVE_CALLBACK_DATA) || defined(RUBY_EVENT_VM)
    rb_add_event_hook(stack_tracy_trap, RUBY_EVENT_CALL | RUBY_EVENT_C_CALL | RUBY_EVENT_RETURN | RUBY_EVENT_C_RETURN, 0);
  #else
    rb_add_event_hook(stack_tracy_trap, RUBY_EVENT_CALL | RUBY_EVENT_C_CALL | RUBY_EVENT_RETURN | RUBY_EVENT_C_RETURN);
  #endif

  size = 0, trace = false;

  return Qnil;
}

VALUE stack_tracy_stop(VALUE self) {
  VALUE events, event;
  ID id;
  const char *method;
  int i;

  rb_remove_event_hook(stack_tracy_trap);

  events = rb_ary_new();

  for (i = 0; i < size - 1; i++) {
    method = rb_id2name((ID) stack[i].method);
    if (method != NULL) {
      event = rb_funcall(cEventInfo, rb_intern("new"), 0);
      rb_iv_set(event, "@event", rb_str_new2(event_name(stack[i].event)));
      rb_iv_set(event, "@file", rb_str_new2(stack[i].file));
      rb_iv_set(event, "@line", rb_int_new(stack[i].line));
      rb_iv_set(event, "@singleton", stack[i].singleton);
      rb_iv_set(event, "@object", rb_str_new2(rb_class2name((VALUE) stack[i].object)));
      rb_iv_set(event, "@method", rb_str_new2(method));
      rb_iv_set(event, "@nsec", rb_float_new(stack[i].nsec));
      rb_ary_push(events, event);
    }
  }

  rb_iv_set(mStackTracy, "@stack_trace", events);

  return Qnil;
}

void Init_stack_tracy() {
  mStackTracy = rb_const_get(rb_cObject, rb_intern("StackTracy"));
  cEventInfo = rb_const_get(mStackTracy, rb_intern("EventInfo"));
  rb_define_singleton_method(mStackTracy, "start", stack_tracy_start, 0);
  rb_define_singleton_method(mStackTracy, "stop", stack_tracy_stop, 0);
}