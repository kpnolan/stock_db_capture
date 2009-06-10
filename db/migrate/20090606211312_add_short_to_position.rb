class AddShortToPosition < ActiveRecord::Migration
  def self.up
    add_column :positions, :short, :boolean
  end

  def self.down
    remove_column :positions, :short
  end
end
