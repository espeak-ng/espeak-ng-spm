#pragma once
#include_next <ctype.h>

/*
 This is a dirty hack to avoid system() calls on iOS and make compiler happy.
 See https://github.com/espeak-ng/espeak-ng/issues/1468
 */

static inline int _no_system() { return -1; }
#define system(...) _no_system()
