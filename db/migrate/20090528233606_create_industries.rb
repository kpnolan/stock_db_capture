class CreateIndustries < ActiveRecord::Migration
  def self.up
    create_table :industries, :force => true do |t|
      t.string :name
    end
  end

  def self.down
    drop_table :industries
  end
end
