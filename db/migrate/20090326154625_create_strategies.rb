class CreateStrategies < ActiveRecord::Migration
  def self.up
    create_table :strategies, :force => true do |t|
      t.string :name
      t.string :description
      t.string :filename
    end
  end

  def self.down
    drop_table :strategies
  end
end
