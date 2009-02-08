class AddDateToLiveQuote < ActiveRecord::Migration
  def self.up
    add_column :live_quotes, :date, :date
  end

  def self.down
    remove_column :live_quotes, :date
  end
end
