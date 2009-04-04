class AddIndexToStrategy < ActiveRecord::Migration
  def self.up
    add_index :strategies, :name, :unique => true
  end

  def self.down
    remove_index :strategies, :name
  end
end
