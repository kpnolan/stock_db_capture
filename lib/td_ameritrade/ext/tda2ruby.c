// Copyright © Kevin P. Nolan 2009 All Rights Reserved.
// Include the Ruby headers and goodies
#include "ruby.h"
#include <stdio.h>
#include <time.h>

// Defining a space for information and references about the module to be stored internally
VALUE Tda2Ruby = Qnil;
VALUE tda_buff_index = INT2FIX(0);
VALUE time_klass;
VALUE snapshot_exception;


VALUE next_ts(unsigned char* str);

// Prototype for the initialization method - Ruby calls this, not you
void Init_tda2ruby();

// Prototype for our method 'test1' - methods are prefixed by 'method_' here
VALUE method_parse_header(VALUE self, VALUE buff);
VALUE method_parse_bar(VALUE self, VALUE buff);
VALUE method_parse_bar_stream(VALUE self, VALUE buff);
VALUE method_parse_snapshot(VALUE self, VALUE buff);
VALUE method_parse_snapshot_bar(VALUE self, VALUE buff);

// The initialization method for this module
void Init_tda2ruby() {
  Tda2Ruby = rb_define_module("Tda2Ruby");
  rb_define_readonly_variable("tda_buff_index", &tda_buff_index);
  rb_define_method(Tda2Ruby, "parse_header", method_parse_header, 1);
  rb_define_method(Tda2Ruby, "parse_bar", method_parse_bar, 1);
  rb_define_method(Tda2Ruby, "parse_bar_stream", method_parse_bar_stream, 1);
  rb_define_method(Tda2Ruby, "parse_snapshot", method_parse_snapshot, 1);
  rb_define_method(Tda2Ruby, "parse_snapshot_bar", method_parse_snapshot_bar, 1);
  snapshot_exception = rb_define_class("SnapshotProtocolError", rb_eException);
  time_klass = rb_const_get(rb_cObject, rb_intern("Time"));
}

inline VALUE uint2rb(unsigned char* str) {
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

inline VALUE ushort2rb(unsigned char* str) {
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

  return tmp;
}

inline VALUE float2rb(unsigned char* str, float scale) {
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
  int error_code;
  short symbol_length = 0;
  int error_length = 0;
  symbol_length = error_code = 0;
  //
  // grab the symbol count one byte at a time
  //
  rsymbol_count = uint2rb(str);
  i += 4;
  //
  // Same with the 2 byte symbol length
  //
  symbol_length = ushort2rb(&str[i]);
  i += 2;
  //
  // grab the symbol (stored on the stack)
  //
  int j;
  for (j = 0; j < symbol_length; j++)
    symbol[j] = str[i++];
  rsymbol = rb_str_new(symbol, (long)symbol_length);      // No free `cause it was on the stack
  //
  // One byte error code either 0 or 1
  //
  error_code = str[i++];
  //
  // if is non-zero (1) it means we have an error, so we have to grab the variable
  // length error message and store on the heap (it will be converted to a ruby string and freed later on)
  if ( error_code > 0 ) {
    error_length = ushort2rb(&str[i]);
    i += 2;

    error_text = malloc(error_length+1);
    for (j = 0; j < error_length; j++)
      error_text[j] = str[i++];
    rerror_string = rb_str_new(error_text, (long)error_length);
    free(error_text);
  }
  //
  // Now we are ready for the bar count, which is 4 bytes
  //
  rbar_count = uint2rb(&str[i]);
  i += 4;
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
  //
  // form the array of [timestamp, close, high, low, open, volume]
  //
  bar_ary = rb_ary_new();
  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));    // close
  i += sizeof(float);
  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));    // high
  i += sizeof(float);
  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));    // low
  i += sizeof(float);
  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));    // open
  i += sizeof(float);
  rb_ary_push(bar_ary, float2rb(&str[i], 100.0)); // volume
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

VALUE method_parse_bar_stream(VALUE self, VALUE buff) {
  int i = 0;
  VALUE bar_ary = rb_ary_new();
  char* str = StringValuePtr(buff);
  if (str[i] != 'S')
    rb_warn("First byte of message not S");
  i += sizeof(char);
  int msg_len = ushort2rb(&str[i]);
  i += sizeof(short);
  i += sizeof(short);                               // skip SSID

  int symlen = ushort2rb(&str[i]);
  i += sizeof(short);

  rb_ary_push(bar_ary, rb_str_new(&str[i], (long)symlen));  // symbol
  i += symlen;
  i += sizeof(char);                                // skip id

  rb_ary_push(bar_ary, uint2rb(&str[i]));           // sequence
  i += sizeof(int);
  i += sizeof(char);                                // skip id

  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));     // open
  i += sizeof(float);
  i += sizeof(char);                                // skip id

  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));     // high
  i += sizeof(float);
  i += sizeof(char);                                // skip id

  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));     // low
  i += sizeof(float);
  i += sizeof(char);                                // skip id

  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));     // close
  i += sizeof(float);
  i += sizeof(char);                                // skip id

  rb_ary_push(bar_ary, uint2rb(&str[i]));           // volume
  i += sizeof(float);
  i += sizeof(char);                                // skip id

  rb_ary_push(bar_ary, uint2rb(&str[i]));           // seconds since midnight
  i += sizeof(int);
  i += sizeof(char);                                // skip id

  rb_ary_push(bar_ary, uint2rb(&str[i]));           // days since epoch
  i += sizeof(int);
  i += sizeof(char);                                // skip id
}

VALUE method_parse_snapshot(VALUE self, VALUE buff) {
  VALUE header_ary = rb_ary_new();
  VALUE rsymbol;
  VALUE rstatus;
  VALUE rpayload;
  char* str = StringValuePtr(buff);
  unsigned int i = 0;
  unsigned short status;

  char symbol[10+1];
  short symbol_length = 0;
  short msglen = 0;
  unsigned int rpayld_len = 0;
  char* payld_ptr = 0;

  if (str[i] != 'N')
    rb_warn("First byte of message not N");
  i += sizeof(char);
  i += sizeof(short);                              // skit snapshot ID len
  i += sizeof(short);                              // skip snapshot ID
  msglen = uint2rb(&str[i]);                       // get entire msg len
  i += sizeof(int);
  i += sizeof(short);                              // skip SID
  //
  // grab the symbol (stored on the stack)
  //
  symbol_length = ushort2rb(&str[i]);
  i += sizeof(short);
  int j;
  for (j = 0; j < symbol_length; j++)
    symbol[j] = str[i++];
  rsymbol = rb_str_new(symbol, (long)symbol_length);      // make rb str

  status = *(unsigned short*)&str[i];
  if ( status != 0 )
    rb_raise(snapshot_exception, "status is not zero");

  rstatus = ushort2rb(&str[i]);
  i += sizeof(short);

  rpayld_len = uint2rb(&str[i]);                   // payload len. we use this to know when we're done
  i += sizeof(int);
  payld_ptr = &str[i];

  rpayload = rb_str_new(payld_ptr, rpayld_len);
  rb_ary_push(header_ary, rsymbol);
  rb_ary_push(header_ary, rstatus);
  rb_ary_push(header_ary, rpayload);

  return ( header_ary );
}

//
// If a bar has data, parse if and append the data to the ruby array.
// If the bar has no data, the first char will be a semi-colon.
//
VALUE method_parse_snapshot_bar(VALUE self, VALUE buff) {
  unsigned int i = FIX2INT(tda_buff_index);
  long len;
  char* str = rb_str2cstr(buff, &len);
  VALUE rsymbol, bar_ary;
  char symbol[10], c;

  if ( i >= len )
    return ( Qtrue );

  if ( *str == ';' ) {                              // means the bar is empty
    tda_buff_index = UINT2NUM(++i);                 // remember position in buffer
    return ( Qnil );                                // return nil for empty bar
  }

  bar_ary = rb_ary_new();                           // allocate bar array

  char* symptr = symbol;
  while ( (c = str[i++]) != ',' )                  // unknown symbol len -- delim by comma
    *symptr++ = c;
  symptr[-1] = '\0';                                // terminate symbol
  rsymbol = rb_str_new2(symbol);
  rb_ary_push(bar_ary, rsymbol);                    // becomes first elem of array

  rb_ary_push(bar_ary, uint2rb(&str[i]));           // sequence number
  i += sizeof(int);
  i += sizeof(char);                                // skip comma

  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));     // open
  i += sizeof(float);
  i += sizeof(char);                                // skip comma

  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));     // high
  i += sizeof(float);
  i += sizeof(char);                                // skip comma

  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));     // low
  i += sizeof(float);
  i += sizeof(char);                                // skip comma

  rb_ary_push(bar_ary, float2rb(&str[i], 1.0));     // close
  i += sizeof(float);
  i += sizeof(char);                                // skip comma

  rb_ary_push(bar_ary, uint2rb(&str[i]));           // volume
  i += sizeof(float);
  i += sizeof(char);                                // skip comma

  rb_ary_push(bar_ary, uint2rb(&str[i]));           // seconds since midnight
  i += sizeof(int);
  i += sizeof(char);                                // skip comma

  rb_ary_push(bar_ary, uint2rb(&str[i]));           // days since epoch
  i += sizeof(int);

  if ( str[i] != ';' )
    rb_warn("End of bar not ';'");
  i += sizeof(char);                                // skip id

  tda_buff_index = UINT2NUM(i);                     // remember position in buffer

  return ( bar_ary );                              // return bar_ary
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





