class CreateIntraSnapshots < ActiveRecord::Migration
  def self.up
    create_table :intra_snapshots, :force => true do |t|
      t.integer :ticker_id
      t.integer :interval
      t.datetime :start_time
      t.float :open
      t.float :close
      t.float :high
      t.float :low
      t.integer :volume
    end
  end

  def self.down
    drop_table :intra_snapshots
  end
end
