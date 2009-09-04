module TsPersistence
  def persist_all

  end

  def compute_and_persist(position, method_hash)
    method_order = Timeseries.optimize_prefetch(method_hash)
    method_order.each do |pair|
      send(pair.first, pair.second)
    end
    results = method_hash.values.map { |v| v[:result] }
    persist(position, results)
  end

  def persist(position, keys)
    position_id = position.id
    return unless PositionSeries.find_by_position_id(position_id).nil?
    timevec = self.timevec[index_range]
    keys.each do |k|
      indicator_id = Indicator.find_by_name(k.to_s).id
      results = vector_for(k)
      timevec.each_with_index do |time, i|
        begin
          PositionSeries.create(:position_id => position_id, :indicator_id => indicator_id, :date => time.to_date, :value => results[i])
        rescue Exception => e
          puts "#{symbol} #{k} index: #{i}"
          puts results.to_a.inspect
          debugger
        end
      end
    end
  end
end
