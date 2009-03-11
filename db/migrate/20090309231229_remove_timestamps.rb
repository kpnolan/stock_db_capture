class RemoveTimestamps < ActiveRecord::Migration
  def self.up
    remove_column :derived_value_types, :created_at
    remove_column :derived_value_types, :updated_at
    remove_column :derived_values, :created_at
    remove_column :derived_values, :updated_at
  end

  def self.down
    add_column :derived_value_types, :created_at, :datetime
    add_column :derived_value_types, :updated_at, :datetime
    add_column :derived_values, :created_at, :datetime
    add_column :derived_values, :updated_at, :datetime
  end
end
