require 'date'
require 'benchmark'
require 'starling'

starling = Starling.new('127.0.0.1:22122')

Foo = Struct.new(:a, :b, :c, :d)
foo = Foo.new(1,2,3,4)

date = Date.today
t = Time.now
sary = [1,2,3,4,5]
snary = [[1,2,3,4], [1,2,3,4]]

n = 50_000

to_jd = lambda { |d| date.jd }
from_jd = lambda { |jd| Date.jd(jd) }

r = 1..100
dr = Date.parse('2009-12-31')..Date.parse('2010-2-14')
tp = [1, Date.today..Date.today+1]

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
#  x.report("RTProxy")        { n.times { starling.set(:proxy, tp); tpp = starling.get(:proxy) } }
  x.report("RTProxy2")   { n.times { starling.set(:proxy, tp) }; n.times { tpp = starling.get(:proxy) } }

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



