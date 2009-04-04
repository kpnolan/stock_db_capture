class AddParamsYamlToStrategy < ActiveRecord::Migration
  def self.up
    add_column :strategies, :params_yaml, :string
    remove_column :strategies, :filename
  end

  def self.down
    remove_column :strategies, :params_yaml
    remove_column :strategies, :filename, :string
  end
end
