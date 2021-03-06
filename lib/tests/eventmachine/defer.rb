#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
require 'eventmachine'

class MyDeferrable
  include EM::Deferrable
  def go(str)
    puts "Deferrable: #{Thread.current}"
    puts "Go #{str} go"
  end
end
EM.run do
  s = EM.spawn do
    puts "Spawn: #{Thread.current}"
  end
  df = MyDeferrable.new
  df.callback do |x|
    df.go(x)
  end
  EM.add_timer(1) do
    puts "Timer: #{Thread.current}"
    df.set_deferred_status :succeeded, "SpeedRacer"
  end
  EM.add_timer(2) do
    25.times do |i|
      EM.defer do
        puts "Defer:#{i} #{Thread.current}"
        sleep(5)
      end
    end
  end
  EM.add_timer(3) do
    puts "3 sec timer"
  end

  EM.add_timer(10) do
    EM.stop
  end
end
