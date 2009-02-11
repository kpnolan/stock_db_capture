class CreatePimaryKeyIds < ActiveRecord::Migration
  def self.up
    create_table :pimary_key_ids do |t|
      t.string :table_name
      t.integer :auto_increment
    end
  end

  def self.down
    drop_table :pimary_key_ids
  end
end
