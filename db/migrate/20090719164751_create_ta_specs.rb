class CreateTaSpecs < ActiveRecord::Migration
  def self.up
    create_table :ta_specs do |t|
      t.integer :indicator_id
      t.integer :time_period
    end
  end

  def self.down
    drop_table :ta_specs
  end
end
