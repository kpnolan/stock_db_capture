class AddWeekToPosition < ActiveRecord::Migration
  def self.up
    add_column :positions, :week, :integer
  end

  def self.down
    remove_column :positions, :week
  end
end
