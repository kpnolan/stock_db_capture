class CreatePlotAttributes < ActiveRecord::Migration
  def self.up
    create_table :plot_attributes, :force => true do |t|
      t.string :name
      t.integer :ticker_id
      t.string :type
      t.datetime :anchor_date
      t.integer :period
      t.string :attributes
    end
  end

  def self.down
    drop_table :plot_attributes
  end
end
