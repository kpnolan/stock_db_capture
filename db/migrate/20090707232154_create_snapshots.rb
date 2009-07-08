class CreateSnapshots < ActiveRecord::Migration
  def self.up
    create_table :snapshots, :force => true do |t|
      t.integer :ticker_id
      t.datetime :snaptime
      t.integer :seq
      t.float :open
      t.float :high
      t.float :low
      t.float :close
      t.integer :volume
      t.integer :accum_volume
      t.integer :secmid
    end
  end

  def self.down
    drop_table :snapshots
  end
end
