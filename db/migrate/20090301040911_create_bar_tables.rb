class CreateBarTables < ActiveRecord::Migration
  def self.up
    [5, 10, 30, 60].each do |res|
      Aggregate.connection.execute "CREATE TABLE bar_#{res}s LIKE aggregates"
    end
  end

  def self.down
    [5, 10, 30, 60].each do |res|
      Aggregate.connection.execute "DROP TABLE bar_#{res}s"
    end
  end
end
