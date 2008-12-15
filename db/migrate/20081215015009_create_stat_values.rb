class CreateStatValues < ActiveRecord::Migration
  def self.up
    create_table :stat_values, :force => true do |t|
      t.integer :historical_attribute_id
      t.integer :ticker_id
      t.date :start_date
      t.date :end_date
      t.integer :sample_count
      t.float :mean
      t.float :min
      t.float :max
      t.float :stddev
      t.float :absdev
      t.float :skew
      t.float :kurtosis
      t.float :slope
      t.float :yinter
      t.float :cov00
      t.float :cov01
      t.float :cov11
      t.float :chisq
      t.datetime :created_at
      t.datetime :updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :stat_values
  end
end
