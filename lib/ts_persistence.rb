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
