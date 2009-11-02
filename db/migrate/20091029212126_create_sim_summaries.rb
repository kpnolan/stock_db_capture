class CreateSimSummaries < ActiveRecord::Migration
  def self.up
    create_table :sim_summaries, :force => true do |t|
      t.date :sim_date
      t.integer :positions_held
      t.integer :positions_available
      t.float :portfolio_value
      t.float :cash_balance
    end
  end

  def self.down
    drop_table :sim_summaries
  end
end
