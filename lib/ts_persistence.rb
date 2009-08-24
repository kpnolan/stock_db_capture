module TsPersistence
  def persist_all

  end

  def persist(position, *keys)
    position_id = position.id
    return unless PositionSeries.find_by_position_id(position_id).nil?
    timevec = self.timevec[index_range]
    keys.each do |k|
      indicator_id = Indicator.find_by_name(k.to_s)[:id]
      results = vector_for(k)
      timevec.each_with_index do |time, i|
        PositionSeries.create(:position_id => position_id, :indicator_id => indicator_id, :date => time.to_date, :value => results[i])
      end
    end
  end
end
