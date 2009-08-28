class CreateEntryStrategies < ActiveRecord::Migration
  def self.up
    create_table :entry_strategies, :force => true do |t|
      t.string :name
      t.string :params
      t.string :description
    end
  end

  def self.down
    drop_table :entry_strategies
  end
end
