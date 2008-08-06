class CreateExchanges < ActiveRecord::Migration
  def self.up
    create_table :exchanges do |t|
      t.string :symbol, :limit => 7
      t.string :name
    end
  end

  def self.down
    drop_table :exchanges
  end
end
