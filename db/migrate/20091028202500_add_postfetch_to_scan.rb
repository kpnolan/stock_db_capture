class AddPostfetchToScan < ActiveRecord::Migration
  def self.up
    add_column :scans, :postfetch, :integer
  end

  def self.down
    remove_column :scans, :postfetch
  end
end
