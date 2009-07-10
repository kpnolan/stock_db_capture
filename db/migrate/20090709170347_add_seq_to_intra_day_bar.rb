class AddSeqToIntraDayBar < ActiveRecord::Migration
  include LoadBars

  def self.up
    add_column :intra_day_bars, :seq, :integer
    backfill_seq()
  end

  def self.down
    remove_column :intra_day_bars, :seq
  end
end
