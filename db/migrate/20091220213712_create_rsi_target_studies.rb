class CreateRsiTargetStudies < ActiveRecord::Migration
  def self.up
    create_table :rsi_target_studies do |t|
      t.integer :ticker_id
      t.date :start_date
      t.date :end_date
      t.integer :time_period
      t.float :slope
      t.float :chisq
      t.float :rsi
      t.float :prior_price
      t.float :last_price
      t.float :pos_delta
      t.float :neg_delta
      t.float :pos_delta1
      t.float :pos_delta_plus
      t.float :pos_delta_minus
      t.float :neg_delta_plus
      t.float :neg_delta_minus
      t.float :pos_delta1_plus
      t.float :pos_delta1_minus
      t.float :pos_delta_plus_ratio
      t.float :pos_delta_minus_ratio
      t.float :neg_delta_plus_ratio
      t.float :neg_delta_minus_ratio
      t.float :pos_delta1_plus_ratio
      t.float :pos_delta1_minus_ratio
    end
  end

  def self.down
    drop_table :rsi_target_studies
  end
end
