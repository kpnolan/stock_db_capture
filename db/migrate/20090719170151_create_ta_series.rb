class CreateTaSeries < ActiveRecord::Migration
  def self.up
    create_table(:ta_series, :options => 'ENGINE=MYISAM') do |t|
      t.integer :ticker_id, :references => nil
      t.integer :ta_spec_id, :references => nil
      t.datetime :stime
      t.float :value
    end
  end

  def self.down
    drop_table :ta_series
  end
end
