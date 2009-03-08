class CreateDerivedValues < ActiveRecord::Migration
  def self.up
    create_table :derived_values do |t|
      t.integer :ticker_id
      t.integer :derived_value_type_id
      t.date :date
      t.datetime :time
      t.float :value

      t.timestamps
    end
  end

  def self.down
    drop_table :derived_values
  end
end
