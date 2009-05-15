// Include the Ruby headers and goodies
#include "ruby.h"

// Defining a space for information and references about the module to be stored internally
VALUE Tda2ruby = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_tda2ruby();

// Prototype for our method 'test1' - methods are prefixed by 'method_' here
VALUE method_parse_header(VALUE self);

// The initialization method for this module
void Init_tda2ruby() {
  Tda2Ruby = rb_define_module("Tda2Ruby");
  rb_define_method(Tda2Ruby, "parse_header", method_parse_header, 1);
  rb_define_method(Tda2Ruby, "parse_bar", method_parse_bar, 1);
}

// Our 'test1' method.. it simply returns a value of '10' for now.
VALUE method_parse_header(VALUE self, VALUE buff) {
  //
  // Ruby Objects
  //
  VALUE rb_symbol = T_NIL;
  VAlUE rb_symbol_count = T_NIL;
  VALUE rb_error_string = T_NIL;
  VALUE rb_bar_count = T_NIL;
  VALUE rb_ret_ary = T_NIL;
  //
  // C objects
  //
  char* str = StringValuePtr(buff);
  int i = 0;
  char symbol[8];
  char* error_text = 0;
  int symbol_count, symbol_length, error_code, bar_count;
  int error_length;
  symbol_count = symbol_length = error_code = bar_count = 0;
  //
  // grab the symbol count one byte at a time
  //
  symbol_count |= str[i++];
  symbol_count << 8;
  symbol_count |= str[i++];
  symbol_count << 8;
  symbol_count |= str[i++];
  symbol_count << 8;
  symbol_count |= str[i++];
  rb_symbol_count = INT2NUM(symbol_count);
  //
  // Same with the 2 byte symbol length
  //
  symbol_length |= str[i++];
  symbol_length << 8;
  symbol_length |= str[i++];
  //
  // grab the symbol (stored on the stack)
  //
  for (int j = 0; i < symbol_length; j++)
    symbol[j] = str[i++];
  rb_symbol = rb_string_new(symbol, (long)symbol_length);      // No free `cause it was on the stack
  //
  // One byte error code either 0 or 1
  //
  error_code = str[i++];
  //
  // if is non-zero (1) it means we have an error, so we have to grab the variable
  // length error message and store on the heap (it will be converted to a ruby string and freed later on)
  if error_code > 0 {
      error_length |= str[i++];
      error_length << 8;
      error_length |= str[i++];

      error_text = malloc(error_length+1);
      for (int j = 0; i < error_length; j++)
        error_text[j] = str[i++];
    }
  rb_error_string = rb_string_new(error_text, (long)error_length);
  free(error_text);
  //
  // Now we are ready for the bar count, which is 4 bytes
  //
  bar_count |= str[i++];
  bar_count << 8;
  bar_count |= str[i++];
  bar_count << 8;
  bar_count |= str[i++];
  bar_count << 8;
  bar_count |= str[i++];
  rb_symbol_count = INT2NUM(symbol_count);
  //
  // Now we will package the 4 ruby objects into a ruby array (hey, it's easy)
  //
  rb_ret_ary = rb_ary_new();
  rb_ary_push(rb_ret_ary, rb_symbol_count);
  rb_ary_push(rb_ret_ary, rb_symbol);
  rb_ary_push(rb_ret_ary, rb_bar_count);
  if (error_length > 0)
    rb_ary_push(rb_ret_ary, rb_error_string);
}

