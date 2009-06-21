class AddIndexToStudy < ActiveRecord::Migration
  def self.up
    add_index :studies, [:name, :version, :sub_version, :iteration ], :unique => true
  end

  def self.down
    remove_index :studies, :column => [:name, :version, :sub_version, :iteration ]
  end
end
