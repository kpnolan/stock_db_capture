module Task
  module RPCTypes
    #
    # PositionProxy is a reference to a position, i.e. the elements of the composite key to that it can travel across a wire
    # an be de-referenced to yield the referred Position DB record
    #
    PositionProxy = Struct.new(:ticker_id, :time_sec, :indicator_id) do

      def initialize(position)
        time = position.entry_date
        self.ticker_id, self.indicator_id = position.ticker_id, position.etind_id
        self.time_sec = time.acts_like_time? ? time.utc.to_time.to_i : time.acts_like_date? ? time.to_time.localtime.change(:hour => 6, :min => 30).to_i : nil
      end

      def dereference()
        Position.find [ticker_id, Time.at(time_sec).utc, indicator_id]
      end
    end

    def PositionProxy.from_position(position)
      position.to_proxy()
    end

    def PositionProxy.dereference(ary)
      ary[1] = Time.at(ary.second).utc
      Position.find(*ary)
    end

    TimeseriesProxy = Struct.new(:ticker_id, :time_range_secs, :resolution, :params) do

      def initialize(ticker_id, time_range, resolution=1.day, params={ })
        self.ticker_id = ticker_id
        self.time_range_secs = TimeseriesProxy.to_seconds(time_range)
        self.resolution = resolution.seconds.to_i
        self.params = params
      end

      def dereference()
        time_range_= TimeseriesProxy.to_time(time_range_secs)
        Timeseries.new(ticker_id, time_range, resolution, params)
      end
    end

    def TimeseriesProxy.to_seconds(time_range)
      raise ArgumentError, 'arg must be a range of Times' unless time_range.is_a?(Range) && time_range.begin.is_a?(Time) && time_range.end.is_a?(Time)
      time_range.begin.to_i..time_range.end.to_i
    end

    def TimeseriesProxy.to_time(seconds_range)
      raise ArgumentError, 'arg must be a range of Integers represent time values in seconds' unless seconds_range.is_a?(Range) && seconds_range.begin.is_a?(Integer) && seconds_range.end.is_a?(Integer)
      Time.at(seconds_range.begin)..Time.at(seconds_range.end)
    end

    def TimeseriesProxy.dereference(ary)
      ary[1] = TimeseriesProxy.to_time(ary[1])
      Timeseries.new(*ary)
    end

    Displacement = Struct.new(:time, :price, :indicator_id, :ival) do

      def initialize(time, price, symbol_or_id, indicator_value)
        self.time = time.acts_like_time? ? time.to_time : time.is_a?(Date) ? time.to_time.localtime.change(:hour => 6, :min => 30) : nil
        raise ArgumentError, "first arg(a time): #[time} cannot be converted to a Time" if time.nil?
        self.price = price
        self.indicator_id = symbol_or_id.is_a?(Symbol) ? Indicator.lookup(symbol_or_id).id : symbol_or_id
        self.ival = indicator_value
      end

      def to_proxy()
        DisplacementProxy.new(time, price, indicator_id, ival)
      end
    end

    DisplacementProxy = Struct.new(:time_sec, :price, :indicator_id, :ival) do
      def initialize(time, price, symbol_or_id, indicator_value)
        raise ArgumentError, "first arg must be Time or Date time): #[time} cannot be converted to a Time" unless time.acts_like_time? || time.acts_like_date?
        if time.acts_like_time?
          self.time_sec = time.utc.to_time.to_i
        elsif time.acts_like_date?
          self.time_sec = time.to_time.localtime.change(:hour => 6, :min => 30).utc.to_i
        else
          raise ArgumentError, "first arg must be Time or Date time): #[time} cannot be converted to a Time"
        end
        self.price = price
        self.indicator_id = symbol_or_id.is_a?(Symbol) ? Indicator.lookup(symbol_or_id).id : symbol_or_id
        self.ival = indicator_value
      end

      def dereference()
        Displacement.new(Time.at(time_sec).localtime, price, indicator_id, ival)
      end
    end

    def DisplacementProxy.dereference(ary)
      ary[0] = Time.at(ary.first).localtime
      Displacement.new(*ary)
    end
  end
end
