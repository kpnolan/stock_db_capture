class CreateIndicators < ActiveRecord::Migration
  def self.up
    create_table :indicators, :force => true do |t|
      t.string :name
    end
  end

  def self.down
    drop_table :indicators
  end
end
