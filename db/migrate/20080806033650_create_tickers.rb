class CreateTickers < ActiveRecord::Migration
  def self.up
     create_table :tickers do |t|
       t.string :symbol, :limit => 7
       t.string :exchange_id
     end
    add_index :tickers, :symbol, :uniq => true

    create_table :listings do |t|
      create_table_from_fields(t, 'x')
    end
  end

  def self.down
    drop_table :tickers
    drop_table :listings
  end
end
