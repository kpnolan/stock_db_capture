class AddlogrToPosistion < ActiveRecord::Migration
  def self.up
    add_column :positions, :logr, :float
  end

  def self.down
    remove_column :positions, :logr, :float
  end
end
