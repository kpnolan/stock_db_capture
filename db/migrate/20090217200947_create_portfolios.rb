class CreatePortfolios < ActiveRecord::Migration
  def self.up
    create_table :portfolios, :force => true do |t|
      t.string :name
      t.float :initial_value
      t.timestamps
    end
  end

  def self.down
    drop_table :portfolios
  end
end
