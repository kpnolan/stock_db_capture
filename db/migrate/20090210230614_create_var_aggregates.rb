class CreateVarAggregates < ActiveRecord::Migration
  def self.up
    Aggregate.connection.exeucte("create table var_aggregates like aggregates")
  end

  def self.down
    drop_table :var_aggregates
  end
end
