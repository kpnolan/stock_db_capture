class CreateExitStrategies < ActiveRecord::Migration
  def self.up
    create_table :exit_strategies, :force => true do |t|
      t.string :name
      t.string :params
      t.string :description
    end
  end

  def self.down
    drop_table :exit_strategies
  end
end
