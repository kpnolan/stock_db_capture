class AddOpenFlagToStrategies < ActiveRecord::Migration
  def self.up
    rename_column :strategies, :params_yaml, :open_params_yaml
    rename_column :strategies, :description, :open_description
    add_column :strategies, :close_params_yaml, :string
    add_column :strategies, :close_description, :string
  end

  def self.down
    remove_column :strategies, :type
  end
end
