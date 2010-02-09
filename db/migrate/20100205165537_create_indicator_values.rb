class CreateIndicatorValues < ActiveRecord::Migration
  def self.up
    create_table :indicator_values, :force => true do |t|
      t.integer     :indicator_id, :references => nil
      t.references  :valuable, :polymorphic => true, :references => nil
      t.datetime    :itime
      t.float       :value
    end
  end

  def self.down
    drop_table :indicator_values
  end
end
