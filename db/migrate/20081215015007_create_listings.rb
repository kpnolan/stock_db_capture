class CreateListings < ActiveRecord::Migration
  def self.up
    create_table :listings, :force => true do |t|
      t.float :moving_ave_50_days_change_percent_from
      t.float :weeks52_change_from_low
      t.float :weeks52_change_percent_from_low
      t.float :weeks52_range_low
      t.float :weeks52_range_high
      t.float :peg_ratio
      t.float :dividend_yield
      t.string :name
      t.float :price_per_eps_estimate_current_year
      t.float :oneyear_target_price
      t.float :dividend_per_share
      t.float :short_ratio
      t.float :price_persales
      t.float :price_per_eps_estimate_next_year
      t.float :eps
      t.float :moving_ave_50_days
      t.float :price_perbook
      t.date :ex_dividend_date
      t.float :moving_ave_200_days
      t.float :book_value
      t.float :eps_estimate_current_year
      t.float :market_cap
      t.float :pe_ratio
      t.float :moving_ave_200_days_change_from
      t.float :eps_estimate_next_year
      t.integer :ticker_id
      t.float :moving_ave_200_days_change_percent_from
      t.float :eps_estimate_next_quarter
      t.date :dividend_paydate
      t.float :weeks52_change_from_high
      t.float :moving_ave_50_days_change_from
      t.float :ebitda
      t.float :weeks52_change_percent_from_high
      t.timestamps
    end
  end

  def self.down
    drop_table :listings
  end
end
