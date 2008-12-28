class RemoveCreatedAtFromRealTimeQuote < ActiveRecord::Migration
  def self.up
    remove_column :real_time_quotes, :created_at
  end

  def self.down
    add_column :real_time_quotes, :created_at, :datetime
  end
end
