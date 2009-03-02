class CreateContractTypes < ActiveRecord::Migration
  def self.up
    create_table :contract_types, :force => true do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :contract_types
  end
end
