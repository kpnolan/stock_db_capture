require 'benchmark'
require 'ta'

profile = false
rails = true

if profile
  require 'rubygems'
  require 'ruby-prof'
end

include Ta

price = Array.new(75+252) { rand*10.0 }
ts(:ibm, '1/1/2009'.to_date..'1/4/2010'.to_date)

n = 500

RubyProf.start  if profile

Benchmark.bmbm(7) do |x|
  x.report("times:")  { n.times { n.times { } } }                             # Get a baseline control for just the times method
  x.report("rsi2:")   { n.times { out = rsi2(price, 75..(price.length-1)) } } # Run the rsi with a 75 point prefetch 500 times
  x.report("rsi:")    { n.times { out = $ts.rsi(:result => :array); $ts.clear_results }}
  x.report("rvi:")    { n.times { out = $ts.rvi(:result => :array); $ts.clear_results }}
end

if profile
  GC.disable
  results = RubyProf.stop
  GC.enable

  File.open "/work/tdameritrade/stock_db_capture/tmp/raw-benchmark.prof", 'w' do |file|
    RubyProf::CallTreePrinter.new(results).print(file)
  end
end
