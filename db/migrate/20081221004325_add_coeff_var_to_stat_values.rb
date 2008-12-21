class AddCoeffVarToStatValues < ActiveRecord::Migration
  def self.up
    add_column :stat_values, :cv, :float
  end

  def self.down
    remove_column :stat_values, :cv
  end
end
