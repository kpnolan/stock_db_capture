// Include the Ruby headers and goodies
#include "ruby.h"
#include <stdio.h>

// Defining a space for information and references about the module to be stored internally
VALUE Tda2Ruby = Qnil;
VALUE tda_buff_index = INT2FIX(0);
VALUE time_klass;

// Utility routines
inline VALUE next_float(unsigned char* str, float scale);
VALUE convert_timesstamp(char* buf);
VALUE next_ts(unsigned char* str);

// Prototype for the initialization method - Ruby calls this, not you
void Init_tda2ruby();

// Prototype for our method 'test1' - methods are prefixed by 'method_' here
VALUE method_parse_header(VALUE self, VALUE buff);
VALUE method_parse_bar(VALUE self, VALUE buff);

// The initialization method for this module
void Init_tda2ruby() {
  Tda2Ruby = rb_define_module("Tda2Ruby");
  rb_define_readonly_variable("tda_buff_index", &tda_buff_index);
  rb_define_method(Tda2Ruby, "parse_header", method_parse_header, 1);
  rb_define_method(Tda2Ruby, "parse_bar", method_parse_bar, 1);
  time_klass = rb_const_get(rb_cObject, rb_intern("Time"));
}

inline VALUE next_float(unsigned char* str, float scale) {
  //
  // reverse the bytes and convert to float
  //
  unsigned char c;

  union uint_float {
    unsigned int ival;
    float        fval;
  };
  union uint_float tmp;

  tmp.ival = 0;
  c = *str++;
  tmp.ival |= c;
  tmp.ival = tmp.ival << 8;
  c = *str++;
  tmp.ival |= c;
  tmp.ival = tmp.ival << 8;
  c = *str++;
  tmp.ival |= c;
  tmp.ival = tmp.ival << 8;
  c = *str++;
  tmp.ival |= c;

  return rb_float_new((double)tmp.fval*scale);
}

VALUE reversed_uint2rb(unsigned char* str) {
  //
  // revere the byte order and convert to ruby
  //
  union uchar_uint {
    unsigned char c[4];
    unsigned int uival;
  };
  unsigned char* cptr;
  union uchar_uint tmp;

  tmp.uival = 0;
  *cptr = &tmp.c[3];
  printf("cptr: %4x\n", cptr);
  printf("tuival: %4x\n", &tmp.uival);
  printf("ttmp: %4x\n", &tmp);
  //  *cptr-- = *str++;
  //*cptr-- = *str++;
  //*cptr-- = *str++;
  //*cptr-- = *str++;

  return UINT2NUM(tmp.uival);
}

VALUE method_parse_header(VALUE self, VALUE buff) {
  //
  // Ruby Objects
  //
  VALUE rsymbol = T_NIL;
  VALUE rsymbol_count = T_NIL;
  VALUE rerror_string = T_NIL;
  VALUE rbar_count = T_NIL;
  VALUE rret_ary = T_NIL;
  //
  // C objects
  //
  unsigned char* str = (unsigned char*)StringValuePtr(buff);
  unsigned int i = 0;
  char symbol[10+1];
  char* error_text = 0;
  int symbol_count, error_code, bar_count;
  short symbol_length = 0;
  int error_length = 0;
  symbol_count = symbol_length = error_code = bar_count = 0;
  //
  // grab the symbol count one byte at a time
  //
  //rsymbol_count = next_uint(str);
  symbol_count |= str[i++];
  symbol_count = symbol_count << 8;
  symbol_count |= str[i++];
  symbol_count = symbol_count << 8;
  symbol_count |= str[i++];
  symbol_count = symbol_count << 8;
  symbol_count |= str[i++];
  rsymbol_count = UINT2NUM(symbol_count);
  //
  // Same with the 2 byte symbol length
  //
  symbol_length |= str[i++];
  symbol_length = symbol_length << 8;
  symbol_length |= str[i++];
  //
  // grab the symbol (stored on the stack)
  //
  int j;
  for (j = 0; j < symbol_length; j++)
    symbol[j] = str[i++];
  symbol[j] = '\0';
  rsymbol = rb_str_new(symbol, (long)symbol_length);      // No free `cause it was on the stack
  //
  // One byte error code either 0 or 1
  //
  error_code = str[i++];
  //
  // if is non-zero (1) it means we have an error, so we have to grab the variable
  // length error message and store on the heap (it will be converted to a ruby string and freed later on)
  if ( error_code > 0 ) {
    error_length |= str[i++];
    error_length = error_length << 8;
    error_length |= str[i++];

    error_text = malloc(error_length+1);
    for (j = 0; j < error_length; j++)
      error_text[j] = str[i++];
    rerror_string = rb_str_new(error_text, (long)error_length);
    free(error_text);
  }
  //
  // Now we are ready for the bar count, which is 4 bytes
  //
  bar_count |= str[i++];
  bar_count = bar_count << 8;
  bar_count |= str[i++];
  bar_count = bar_count << 8;
  bar_count |= str[i++];
  bar_count = bar_count << 8;
  bar_count |= str[i++];
  rbar_count = INT2NUM(bar_count);
  //
  // Now we will package the 4 ruby objects into a ruby array (hey, it's easy)
  //
  rret_ary = rb_ary_new();
  rb_ary_push(rret_ary, rsymbol_count);
  rb_ary_push(rret_ary, rsymbol);
  rb_ary_push(rret_ary, rbar_count);
  if (error_length > 0)
    rb_ary_push(rret_ary, rerror_string);
  //
  // The last thing is to store the index var back into the Ruby global VAR
  //
  tda_buff_index = INT2FIX(i);

  return rret_ary;
}

VALUE method_parse_bar(VALUE self, VALUE buff) {
  unsigned int i = FIX2INT(tda_buff_index);
  char* str = StringValuePtr(buff);

  VALUE epoch_seconds = T_NIL;
  VALUE bar_ary;
  VALUE timestamp;


  // form the array of [timestamp, close, high, low, open, volume]
  //
  bar_ary = rb_ary_new();
  rb_ary_push(bar_ary, next_float(&str[i], 1.0));    // close
  i += sizeof(float);
  rb_ary_push(bar_ary, next_float(&str[i], 1.0));    // high
  i += sizeof(float);
  rb_ary_push(bar_ary, next_float(&str[i], 1.0));    // low
  i += sizeof(float);
  rb_ary_push(bar_ary, next_float(&str[i], 1.0));    // open
  i += sizeof(float);
  rb_ary_push(bar_ary, next_float(&str[i], 1000.0)); // volume
  i += sizeof(float);
  //
  // grab 8 bytes to form the bignum epoch_seconds
  //
  epoch_seconds = next_ts(&str[i]);
  rb_ary_push(bar_ary, epoch_seconds);
  i += 8;
  //

  //
  // record the number value of buff index
  //
  tda_buff_index = UINT2NUM(i);
  return bar_ary;
}


VALUE next_uint(unsigned char* str) {
  //
  // revere the byte order and convert to ruby
  //
  unsigned int tmp = 0;
  unsigned char c;

  c = *str++;
  tmp |= c;
  tmp = tmp << 8;
  c = *str++;
  tmp |= c;
  tmp = tmp << 8;
  c = *str++;
  tmp |= c;
  tmp = tmp << 8;
  c = *str++;
  tmp |= c;

  return UINT2NUM(tmp);
}

VALUE next_ts(unsigned char* str) {
  //
  // revere the byte order and convert to ruby
  //
  unsigned long long tmp = 0;
  unsigned long long secs = 0;

  time_t secs_t, usecs_t;
  unsigned char c;

  c = *str++;
  tmp |= c;
  tmp = tmp << 8;

  c = *str++;
  tmp |= c;
  tmp = tmp << 8;

  c = *str++;
  tmp |= c;
  tmp = tmp << 8;

  c = *str++;
  tmp |= c;
  tmp = tmp << 8;

  c = *str++;
  tmp |= c;
  tmp = tmp << 8;

  c = *str++;
  tmp |= c;
  tmp = tmp << 8;

  c = *str++;
  tmp |= c;
  tmp = tmp << 8;

  c = *str++;
  tmp |= c;

  secs = tmp / 1000;
  usecs_t = tmp % 1000;
  usecs_t *= 1000;
  secs_t = secs;

  return rb_time_new(secs_t, usecs_t);
}





