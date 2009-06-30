class AddPassToPosition < ActiveRecord::Migration
  def self.up
    add_column :positions, :pass, :integer
  end

  def self.down
    remove_column :positions, :pass
  end
end
