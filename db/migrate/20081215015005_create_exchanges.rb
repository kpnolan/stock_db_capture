class CreateExchanges < ActiveRecord::Migration
  def self.up
    create_table :exchanges, :force => true do |t|
      t.string :symbol
      t.string :name
      t.string :country
      t.string :currency
      t.string :timezone
      t.timestamps
    end
  end

  def self.down
    drop_table :exchanges
  end
end
