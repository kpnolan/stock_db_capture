class CreatePositionsStrategies < ActiveRecord::Migration
  def self.up
    create_table :positions_strategies, :id => false do |t|
      t.integer :strategy_id
      t.integer :position_id
    end
  end

  def self.down
    drop_table :positions_strategies
  end
end
