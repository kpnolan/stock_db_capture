class RenameNormalize < ActiveRecord::Migration
  def self.up
    rename_column :positions, :nomalized_return, :nreturn
  end

  def self.down
    rename_column :positions, :return, :nomalized_return
  end
end
