class CreateTempPositionTemplates < ActiveRecord::Migration
  def self.up
    create_table :temp_position_templates do |t|
      t.integer :ticker_id
      t.date :ettime
      t.float :etprice
      t.float :etival
      t.date :xttime
      t.float :xtprice
      t.float :xtival
      t.date :entry_date
      t.float :entry_price
      t.float :entry_ival
      t.float :exit_price
      t.date :exit_date
      t.float :exit_ival
      t.integer :days_held
      t.float :nreturn
      t.integer :entry_pass
      t.float :roi
      t.float :consumed_margin
      t.integer :volume
    end
  end

  def self.down
    drop_table :temp_position_templates
  end
end
