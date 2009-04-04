class CreatePositionsScans < ActiveRecord::Migration
  def self.up
    create_table :positions_scans, :id => false do |t|
      t.integer :position_id
      t.integer :scan_id
    end
  end

  def self.down
    drop_table :positions_scans
  end
end
