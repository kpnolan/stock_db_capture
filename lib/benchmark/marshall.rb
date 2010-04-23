require 'benchmark'
require 'date'

rails = true
date = Date.today

n = 100000

to_jd = lambda { |d| date.jd }
from_jd = lambda { |jd| Date.jd(jd) }

Benchmark.bmbm(7) do |x|
  x.report("Marshal;")  { n.times { str = Marshal.dump(date); d = Marshal.load(str) } }
  x.report("Julian:")   { n.times { jd = to_jd.call(date); d = from_jd.call(jd) } }
end

