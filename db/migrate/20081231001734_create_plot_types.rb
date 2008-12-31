class CreatePlotTypes < ActiveRecord::Migration
  def self.up
    create_table :plot_types, :force => true do |t|
      t.string :name
      t.string :source_model
      t.string :method
      t.string :time_class
      t.string :resolution
      t.string :inputs
      t.integer :num_outputs
    end
  end

  def self.down
    drop_table :plot_types
  end
end
