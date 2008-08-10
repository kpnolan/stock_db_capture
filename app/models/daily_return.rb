class DailyReturn < ActiveRecord::Base
  belongs_to :ticker

  def symbol=(value)
  end

end
