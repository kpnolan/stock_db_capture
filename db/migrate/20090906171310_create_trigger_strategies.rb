class CreateTriggerStrategies < ActiveRecord::Migration
  def self.up
    create_table :trigger_strategies, :force => true do |t|
      t.string :name
      t.string :params
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :trigger_strategies
  end
end
