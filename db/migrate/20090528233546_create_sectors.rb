class CreateSectors < ActiveRecord::Migration
  def self.up
    create_table :sectors, :force => true do |t|
      t.string :name
    end
  end

  def self.down
    drop_table :sectors
  end
end
