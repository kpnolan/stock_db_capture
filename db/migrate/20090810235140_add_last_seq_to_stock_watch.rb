class AddLastSeqToStockWatch < ActiveRecord::Migration
  def self.up
    add_column :watch_list, :last_seq, :integer
  end

  def self.down
    remove_column :watch_list, :last_seq
  end
end
