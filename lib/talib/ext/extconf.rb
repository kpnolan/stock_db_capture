require 'mkmf'

#find_header("rb_gsl_array.h", "../include-1.8.7")
find_header("rb_gsl_array.h", "../include-1.9.1")
dir_config("talib", "/usr/local/include/ta-lib", "/usr/local/lib")
have_library("ta_lib", "TA_Initialize")

create_makefile("talib")
