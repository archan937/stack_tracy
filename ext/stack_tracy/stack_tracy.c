#include "stack_tracy.h"

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
  struct timespec time;

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

  singleton = false;
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

  info.event = event_name(event);
  info.file = (char *)rb_sourcefile();
  info.line = rb_sourceline();
  info.singleton = singleton;
  info.object = rb_class2name(singleton ? self : klass);
  info.method = rb_id2name(id);

  struct timespec ts;
  #if defined(_POSIX_TIMERS) && _POSIX_TIMERS > 0
  clock_gettime(CLOCK_REALTIME, &ts);
  #else
  struct timeval tv;
  gettimeofday(&tv, NULL);
  ts.tv_sec = tv.tv_sec;
  ts.tv_nsec = tv.tv_usec * 1000;
  #endif
  info.timestamp = (uint) ts.tv_nsec;

  size = size + 1;
  stack = (EventInfo *) realloc (stack, size * sizeof(EventInfo));
  stack[size - 1] = info;
}

VALUE stack_tracy_start(VALUE self) {
  #if defined(RB_EVENT_HOOKS_HAVE_CALLBACK_DATA) || defined(RUBY_EVENT_VM)
    rb_add_event_hook(stack_tracy_trap, RUBY_EVENT_CALL | RUBY_EVENT_C_CALL | RUBY_EVENT_RETURN | RUBY_EVENT_C_RETURN, 0);
  #else
    rb_add_event_hook(stack_tracy_trap, RUBY_EVENT_CALL | RUBY_EVENT_C_CALL | RUBY_EVENT_RETURN | RUBY_EVENT_C_RETURN);
  #endif
  size = 0, trace = false;
}

VALUE stack_tracy_stop(VALUE self) {
  int i;
  VALUE info, data;

  rb_remove_event_hook(stack_tracy_trap);
  data = rb_ary_new();

  for (i = 0; i < size; i++) {
    info = rb_funcall(cEventInfo, rb_intern("new"), 0);

    rb_iv_set(info, "@event", rb_str_new2(stack[i].event));
    rb_iv_set(info, "@file", rb_str_new2(stack[i].file));
    rb_iv_set(info, "@line", rb_int_new(stack[i].line));
    rb_iv_set(info, "@singleton", stack[i].singleton);
    rb_iv_set(info, "@object", rb_str_new2(stack[i].object));
    if (stack[i].method != NULL) {
      rb_iv_set(info, "@method", rb_str_new2(stack[i].method));
    }
    rb_iv_set(info, "@timestamp", rb_int_new(stack[i].timestamp));

    rb_ary_push(data, info);
  }

  rb_funcall(mStackTracy, rb_intern("send"), 2, rb_str_new2("store"), data);
  rb_funcall(mStackTracy, rb_intern("print"), 0);
}

void Init_stack_tracy() {
  mStackTracy = rb_const_get(rb_cObject, rb_intern("StackTracy"));
  cEventInfo = rb_const_get(mStackTracy, rb_intern("EventInfo"));
  rb_define_singleton_method(mStackTracy, "start", stack_tracy_start, 0);
  rb_define_singleton_method(mStackTracy, "stop", stack_tracy_stop, 0);
}