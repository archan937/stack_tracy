#ifndef STACK_TRACY_H
#define STACK_TRACY_H

#include <ruby.h>
#include <stdbool.h>
#include <time.h>
#include <sys/time.h>

typedef struct event_info_t {
  rb_event_flag_t event;
  const char *file;
  int line;
  bool singleton;
  const VALUE *object;
  const ID *method;
  double nsec;
} EventInfo;

static VALUE mStackTracy;
static VALUE cEventInfo;
static EventInfo *stack;

static int size;
static bool trace;

static double nsec();
static const char *event_name(rb_event_flag_t event);

#if defined(RB_EVENT_HOOKS_HAVE_CALLBACK_DATA) || defined(RUBY_EVENT_VM)
static void stack_tracy_trap(rb_event_flag_t event, VALUE data, VALUE self, ID id, VALUE klass);
#else
static void stack_tracy_trap(rb_event_flag_t event, NODE *node, VALUE self, ID id, VALUE klass);
#endif

VALUE stack_tracy_start(VALUE self);
VALUE stack_tracy_stop(VALUE self);
void Init_stack_tracy();

#endif