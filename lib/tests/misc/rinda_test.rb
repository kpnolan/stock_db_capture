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
require 'rinda/rinda'
require 'rinda/ring'
require 'rinda/tuplespace'
require 'date'
require 'benchmark'
require 'date'
require '../rpctypes'

DRb.start_service
ring_server = Rinda::RingFinger.primary
ts = ring_server.read([:name, :TupleSpace, nil, nil])[2]
fabric = Rinda::TupleSpace.new ts

Foo = Struct.new(:a, :b, :c, :d)
foo = Foo.new(1,2,3,4)

date = Date.today
t = Time.now
sary = [1,2,3,4,5]
snary = [[1,2,3,4], [1,2,3,4]]

n = 100000

to_jd = lambda { |d| date.jd }
from_jd = lambda { |jd| Date.jd(jd) }

r = 1..100
dr = Date.parse('2009-12-31')..Date.parse('2010-2-14')
tp = Task::RPCTypes::TimeseriesProxy.new(1, Date.today..Date.today+1)

Benchmark.bmbm(7) do |x|
#  x.report("Marshal;")      { n.times { str = Marshal.dump(date); d = Marshal.load(str) } }
#  x.report("MarshalA;")      { n.times { str = Marshal.dump(sary); dary = Marshal.load(str) } }
#  x.report("MarshalNA;")      { n.times { str = Marshal.dump(snary); dary = Marshal.load(str) } }
#  x.report("MarshalA;")      { n.times { str = Marshal.dump(sary); dary = Marshal.load(str) } }
#  x.report("MarshalNA;")      { n.times { str = Marshal.dump(snary); dary = Marshal.load(str) } }
#  x.report("MarshalTime;")   { n.times { str = Marshal.dump(t);  tim = Marshal.load(str) } }
#  x.report("MarshalTimSec;") { n.times { str = Marshal.dump(t.to_i()); dt = Time.at(Marshal.load(str)) } }
#  x.report("MarshalFoo:")   { n.times { str = Marshal.dump(foo);  f = Marshal.load(str) } }

#  x.report("StructFoo:")     { n.times { a = foo.to_a; fa = Foo.new(*a) } }
#  x.report("RStructFoo:")    { n.times { fabric.write([:fooo, *foo.to_a]); fa = fabric.take([:fooo, nil, nil, nil, nil]); fa1 = Foo.new(*fa.drop(1)) } }
#  x.report("RFooNil")        { n.times { fabric.write([:fooo, foo]); tf = fabric.take([:fooo, nil])[1] } }
  x.report("RTProxy")        { n.times { fabric.write([:proxy, tp]); tpp = fabric.take([:proxy, Task::RPCTypes::TimeseriesProxy])[1] } }
  x.report("RTProxyNil")     { n.times { fabric.write([:proxy, tp]); tpp = fabric.take([:proxy, nil])[1] } }

  #  x.report("Julian:")       { n.times { jd = to_jd.call(date); d = from_jd.call(jd) } }
#  x.report("RNilJulian")    { n.times { fabric.write([:date1, date.jd]); fabric.take([:date1, nil]) } }
#  x.report("RNilDate")      { n.times { fabric.write([:date3, date]); fabric.take([:date3, nil]) } }
#  x.report("RNilDate")      { n.times { fabric.write([:date4, date]); fabric.take([:date4, Date]) } }
#  x.report("RNilArray")      { n.times { fabric.write([:array1, *sary]); dary = fabric.take([:array1, nil, nil, nil, nil, nil]) } }
#  x.report("RNestArray")     { n.times { fabric.write([:array1, *snary]); dary = fabric.take([:array1, Array, Array]) } }
#  x.report("RDTime")         { n.times { fabric.write([:time1, t]); dt = fabric.take([:time1, Time])[1] } }
#  x.report("RTimeSec")       { n.times { fabric.write([:time1, t.to_i()]); dt = Time.at(fabric.take([:time1, Integer])[1]) } }
end


# fabric.write([:range, r])
# tuple1 = fabric.read([:range, Range])

# fabric.write([:drange, dr])
# tuple2 = fabric.read([:drange, Range])

# fabric.write([:two, [1,2,3], [4,5,6]])
# tuple3 = fabric.read([:two, Array,Array])



# puts "#{tuple1.join(', ')}"
# puts "#{tuple2.join(', ')}"
# puts "#{tuple2[1].begin.class}"
# puts "#{tuple3[1].inspect}"
# puts "#{tuple3[2].inspect}"



