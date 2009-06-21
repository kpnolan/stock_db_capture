class AddVersionToStudy < ActiveRecord::Migration
  def self.up
    add_column :studies, :version, :integer
    add_column :studies, :sub_version, :integer
    add_column :studies, :iteration, :integer
  end

  def self.down
    remove_column :studies, :version
    remove_column :studies, :sub_version
    remove_column :studies, :iteration
  end
end
