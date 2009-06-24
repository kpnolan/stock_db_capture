class AddResultToFactor < ActiveRecord::Migration
  def self.up
    add_column :factors, :result, :string
  end

  def self.down
    remove_column :factors, :result
  end
end
