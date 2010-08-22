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

indicators(:ema) do
  indicator :ema, :time_period => 5
  indicator :ema, :time_period => 14
  indicator :ema, :time_period => 22
  indicator :ema, :time_period => 30
end

indicators(:rsi) do
  indicator :rsi, :time_period => 5
  indicator :rsi, :time_period => 14
  indicator :rsi, :time_period => 22
  indicator :rsi, :time_period => 30
end

indicators(:rvi) do
  indicator :rvi, :time_period => 5
  indicator :rvi, :time_period => 14
  indicator :rvi, :time_period => 22
  indicator :rvi, :time_period => 30
end


populations do
  name = "ta_positions_2009"
  desc "populations of a stocks which held positions in 2009"
  scan name, :start_date => "01/02/2009",
             :end_date => "6/5/2009",
             :join => 'left outer join positions on positions.ticker_id = daily_bars.ticker_id '+
                      'left outer join tickers on tickers.id = positions.ticker_id',
             :order_by => 'positions.ticker_id'
end

run(:resolution => 1.day) do
  apply(:ema, :ta_positions_2009)
  apply(:rsi, :ta_positions_2009)
  apply(:rvi, :ta_positions_2009)
end
