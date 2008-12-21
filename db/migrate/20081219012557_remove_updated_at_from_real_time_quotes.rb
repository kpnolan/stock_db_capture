class RemoveUpdatedAtFromRealTimeQuotes < ActiveRecord::Migration
  def self.up
    remove_column :real_time_quotes, :updated_at
  end

  def self.down
    add_column :real_time_quotes, :updated_at, :datetime
  end
end
