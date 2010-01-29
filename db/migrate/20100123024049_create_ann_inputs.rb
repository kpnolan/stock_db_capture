class CreateAnnInputs < ActiveRecord::Migration
  def self.up
    create_table :ann_inputs do |t|
      t.float :O
      t.float :H
      t.float :L
      t.float :C
      t.float :RSI
      t.integer :V
      t.float :RVIG
      t.float :MACD
      t.float :O0

      t.timestamps
    end
  end

  def self.down
    drop_table :ann_inputs
  end
end
