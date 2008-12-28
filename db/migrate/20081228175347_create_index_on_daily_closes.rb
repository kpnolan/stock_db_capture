class CreateIndexOnDailyCloses < ActiveRecord::Migration
  def self.up
    add_index(:daily_closes, [:ticker_id, :date], :unique => true)
  end

  def self.down
   remove_index(:daily_closes, :column => [:ticker_id, :date])
  end
end
