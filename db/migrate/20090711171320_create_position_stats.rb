class CreatePositionStats < ActiveRecord::Migration
  def self.up
    create_table :position_stats do |t|
      t.integer :position_id
      t.string :name
      t.float :value
    end
  end

  def self.down
    drop_table :position_stats
  end
end
