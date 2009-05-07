class RemovePositionsScans < ActiveRecord::Migration
  def self.up
    drop_table :positions_scans
  end

  def self.down
    create_table :positions_scans, :id => false do |t|
      t.integer :position_id
      t.integer :scan_id
    end
  end
end
