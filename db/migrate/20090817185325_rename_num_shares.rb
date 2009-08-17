class RenameNumShares < ActiveRecord::Migration
  def self.up
    rename_column :tda_positions, :rum_shares, :num_shares
  end

  def self.down
    rename_column :tda_positions, :num_shares, :rum_shares
  end
end
