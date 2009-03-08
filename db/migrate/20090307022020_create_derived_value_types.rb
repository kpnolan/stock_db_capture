class CreateDerivedValueTypes < ActiveRecord::Migration
  def self.up
    create_table :derived_value_types, :force => true do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :derived_value_types
  end
end
