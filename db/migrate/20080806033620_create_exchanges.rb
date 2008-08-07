class CreateExchanges < ActiveRecord::Migration
  def self.up
    create_table :exchanges do |t|
      t.string :symbol
      t.string :name
      t.string :timezone
    end
  end

  def self.down
    drop_table :exchanges
  end
end
