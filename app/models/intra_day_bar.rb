# == Schema Information
# Schema version: 20090528233608
#
# Table name: intra_day_bars
#
#  id         :integer(4)      not null, primary key
#  ticker_id  :integer(4)
#  interval   :integer(4)
#  start_time :datetime
#  open       :float
#  close      :float
#  high       :float
#  volume     :integer(4)
#  delta      :float
#  low        :float
#

class IntraDayBar < ActiveRecord::Base
  extend TableExtract
  extend Plot

  def symbol=(value) ;  end
  def last_trade_date=(value) ;  end

  class << self

    def order ; 'start_time, id'; end
    def time_col ; :start_time ;  end
    def time_convert ; :to_time ;  end
    def time_class ; Time ;  end
    def time_res; 1; end
  end
end
