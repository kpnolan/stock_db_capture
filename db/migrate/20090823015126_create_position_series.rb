class CreatePositionSeries < ActiveRecord::Migration
  def self.up
    create_table :position_series, :force => true, :options => "ENGINE=MYISAM" do |t|
      t.integer :position_id, :references => nil
      t.integer :indicator_id, :references => nil
      t.date    :date
      t.float   :value
    end
  end

  def self.down
    drop_table :position_series
  end
end
