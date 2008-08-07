class Listing < ActiveRecord::Base
  belongs_to :ticker

  def symbol=(name)
  end
end
