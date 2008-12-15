class CreateDailyCloses < ActiveRecord::Migration
  def self.up
    create_table :daily_closes, :force => true do |t|
      t.integer :ticker_id
      t.date :date
      t.float :open
      t.float :close
      t.float :high
      t.float :low
      t.float :adj_close
      t.integer :volume
      t.integer :week
      t.integer :month
      t.timestamps
    end
  end

  def self.down
    drop_table :daily_closes
  end
end
