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
require 'task/rcprime'

module Task
  module RPCTypes
    #
    # NB! Positions used to have a proxy object but dereferencing it reliably in a multi-threaded environment became problematic.
    # Instead, I change the previous composite key to a autoincremented ID column just like the way Rails wants and the "proxy" is
    # simply the value of this ID column as an Integer which can be looked up on no time flat. Using an single primary key makes partitioning
    # more difficult, but more on that later...
    #
    TimeseriesProxy = Struct.new(:ticker_id, :time_range_secs, :resolution, :params) do

      def initialize(ticker_id, time_range, resolution=1.day, params={ })
        self.ticker_id = ticker_id
        self.time_range_secs = TimeseriesProxy.to_seconds(time_range)
        self.resolution = resolution.seconds.to_i
        self.params = params
      end

      def is_proxy?
        true
      end

      def dereference()
        time_range = TimeseriesProxy.to_time(time_range_secs)
        Timeseries.new(ticker_id, time_range, resolution, params)
      end
    end

    def TimeseriesProxy.to_seconds(time_range)
      if time_range.begin.is_a?(Date) && time_range.end.is_a?(Date)
        time_range = time_range.begin.to_time.change(:hour => 6, :min => 30)..time_range.end.to_time.change(:hour => 6, :min => 30)
      end
      raise ArgumentError, 'arg must be a range of Times' unless time_range.is_a?(Range) && time_range.begin.is_a?(Time) && time_range.end.is_a?(Time)
      time_range.begin.to_i..time_range.end.to_i
    end

    def TimeseriesProxy.to_time(seconds_range)
      raise ArgumentError, 'arg must be a range of Integers represent time values in seconds' unless seconds_range.is_a?(Range) && seconds_range.begin.is_a?(Integer) && seconds_range.end.is_a?(Integer)
      Time.at(seconds_range.begin)..Time.at(seconds_range.end)
    end

    Displacement = Struct.new(:time, :price, :indicator_id, :ival) do

      def initialize(time, price, symbol_or_id, indicator_value)
        self.time = time.acts_like_time? ? time.to_time : time.is_a?(Date) ? time.to_time.localtime.change(:hour => 6, :min => 30) : nil
        raise ArgumentError, "first arg: #{time} cannot be converted to a Time" if time.nil?
        self.price = price
        self.indicator_id = symbol_or_id.is_a?(Symbol) ? Indicator.lookup(symbol_or_id).id : symbol_or_id
        self.ival = indicator_value
      end

      def is_proxy?
        false
      end

      def to_proxy()
        DisplacementProxy.new(time, price, indicator_id, ival)
      end
    end

    DisplacementProxy = Struct.new(:time_sec, :price, :indicator_id, :ival) do
      def initialize(time, price, symbol_or_id, indicator_value)
        if time.acts_like_time?
          self.time_sec = time.utc.to_time.to_i
        elsif time.acts_like_date?
          self.time_sec = time.to_time.localtime.change(:hour => 6, :min => 30).utc.to_i
        else
          raise ArgumentError, "first arg must be Time or DateTime, instead it's #{time} which cannot be converted to a Time" unless time.acts_like_time? || time.acts_like_date?
        end
        self.price = price
        self.indicator_id = symbol_or_id.is_a?(Symbol) ? Indicator.lookup(symbol_or_id).id : symbol_or_id
        self.ival = indicator_value
      end

      def is_proxy?
        true
      end

      def dereference()
        Displacement.new(Time.at(time_sec).localtime, price, indicator_id, ival)
      end
    end
  end
end
