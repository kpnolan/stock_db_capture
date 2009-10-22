class CreateSplits < ActiveRecord::Migration
  def self.up
    create_table :splits, :force => true do |t|
      t.integer :ticker_id
      t.date :date
      t.integer :from
      t.integer :to
    end
    add_index :splits, [:ticker_id, :date], :unique => true
  end

  def self.down
    drop_table :splits
  end
end
