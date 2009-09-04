class AddDateToDailyBar < ActiveRecord::Migration
  def self.up
    rename_column :daily_bars, :date, :old_date
    add_column :daily_bars, :date, :datetime
    DailyBar.find_each(:batch_size => 10000) do |db|
      dt = db.old_date.to_time.change(:hour => 6, :min => 30).to_datetime
      db.update_attribute(:date, dt)
    end
  end

  def self.down
    remove_column :daily_bars, :date
    rename_column :daily_bars, :old_date, :date
  end
end
