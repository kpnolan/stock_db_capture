class CreateIntraArchive < ActiveRecord::Migration
  def self.up
    create_table :intra_day_archive, :options => "ENGINE=ARCHIVE", :id => false, :force => true do |t|
      t.integer :ticker_id, :references => nil
      t.integer :interval
      t.datetime :start_time
      t.float :open
      t.float :close
      t.float :high
      t.float :low
      t.integer :volume
      t.integer :accum_valume
      t.float :delta
    end
  end

  def self.down
  end
end
