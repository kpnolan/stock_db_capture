module Backtest
  #
  # A Rssult tuple is of the form [ :result, node_name, ticker_id, time_sec, indicator_id, result-tuple ]
  # The result-tuple is of the form [ time-seconds, price, indicator_id, indicator_value ]
  #
  # Results are directed(bound) to a particular node name. Semantically, a prior node performas a caclulation
  # giving a result which is then packaged up inot this tuple. The node (or stage) needing the result simply
  # takes it from the tuplespace.
  #
  Result = Struct.new(:type, :name, :position, :result) do
    def initialize(name, position, result_ary)
      self.type = :result
      self.name = name
      self.position = position
      self.result = result_ary
    end

    # Send this message to stage named by node_name
    def record()
      raise ArgumentError, "configuration has not been bound" if @@tuplespace.nil?
      raise ArgumentError, "tuplespace has not been bound" if @@tuplespace.nil?
      position_result = position.tuple_id + result
      puts "writing result to (#{name}) result: #{result.join(', ')}"
      @@tuplespace.write([:result, name, *position_result])
    end

    def decode()
      [Time.at(result.first), *result[1..3]]
    end

    def time()
      Time.at(result.first)
    end
  end

  # Wait for position message
  def Result.receive(name, position, timeout=@@default_timeout)
    puts "Result.receive #{name}:#{position}"
    raise ArgumentError, "tuplespace has not been bound" if @@tuplespace.nil?
    position4nils = position.tuple_id + [nil, nil, nil, nil]
    tuple_ary = @@tuplespace.take([:result, name, *position4nils], @@default_timeout)
    puts "Result received: #{tuple_ary.join(', ')}"
    position = Position.find_tuple(*tuple_ary[2..4])
    Result.new(tuple_ary[1], position, tuple_ary[5..8])
  end

  def Result.bind_to_tuplespace(tuplespace)
    @@tuplespace = tuplespace
  end

  def Result.default_timeout=(timeout)
    @@default_timeout = timeout
  end

  def Result.read(name, position)
    raise ArgumentError, "typlespace has not been bound" if @@tuplespace.nil?
    position4nils = position.tuple_id + [nil, nil, nil, nil]
    tuple_ary = @@uplespace.read([:result, name, *position4nils], @@default_timeout)
    position = Position.find_tuple(tuple_ary[2..4])
    Result.new(tuple_ary[1], position, tuple_ary[5..8])
  end

  def Result.read_all(name=nil)
    raise ArgumentError, "typlespace has not been bound" if @@tuplespace.nil?
    position_tuple = [nil, nil, nil]
    result_tuple = [nil, nil, nil, nil]
    @@tuplespace.read_all([:result, name, *(position_tuple+result_tuple)])
  end

  def Result.dump_all(name=nil)
    tuples = read_all(name)
    count = tuples.length
    tuples.each do |tuple|
      puts "[ #{tuple.join(',')} ]"
    end
    puts "#{count} Result tuples found"
  end

  def Result.default_timeout
    @@default_timeout
  end

  def Result.record(name, position, result_ary)
    raise Backtest::RuntimeException, "result must be an array of length 4" unless result_ary.is_a?(Array) && result_ary.length == 4
    time, price, symbol, ivalue = result_ary
    raise Backtest::RuntimeException, "result[0] must be a Time" unless time.is_a?(Time)
    raise Backtest::RuntimeException, "result[1] must be a Numeric" unless price.is_a?(Numeric)
    raise Backtest::RuntimeException, "result[2] must be a Symbol" unless symbol.is_a?(Symbol)
    raise Backtest::RuntimeException, "result[3] must be a Numeric" unless ivalue.is_a?(Numeric)
    res = Result.new(name, position, [time.to_i, price, symbol, ivalue])
    res.record()
  end
end
