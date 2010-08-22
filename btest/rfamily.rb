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

study(:rfamily, :increment => :redo) do
  desc "Study the relationships between the favorite 'r' indicators and nreturn and close"
  factor :rsi, :time_period => 14
#  factor :rvi, :time_period => 14
#  factor :mom, :timer_period => 14
#  factor :extract, :slot => :close
end

populations do
  name = "pos_2003"
  liquid = "min(volume) > 100000"
  year = 2003
  desc "Population of all stocks with a minimum valume of 100000 and have days traded in #{year}"
  scan name, :start_date => "01/02/#{year}", :end_date => "12/31/#{year}", :join => 'join tickers on tickers.id = daily_bars.ticker_id',
             :order_by => 'tickers.symbol'
end

experiment(:timeseries => [:resolution => 1.day ]) do
  run(:rfamily, :bypass => false, :version => :memory, :with => :pos_2003) { }
end
