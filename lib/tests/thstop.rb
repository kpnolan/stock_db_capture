require 'rubygems'
require 'ruby-debug'
require 'thread'

a = Thread.new { print "a"; Thread.stop; print "c" }
   debugger
#   Thread.pass
   print "b"
   a.run
   a.join
   puts
