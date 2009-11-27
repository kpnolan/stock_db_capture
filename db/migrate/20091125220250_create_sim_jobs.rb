class CreateSimJobs < ActiveRecord::Migration
  def self.up
    create_table :sim_jobs, :force => true do |t|
      t.string :user
      t.string :dir
      t.string :prefix
      t.string :position_table
      t.date :start_date
      t.date :end_date
      t.string :output
      t.string :filter_predicate
      t.string :sort_by
      t.float :initial_balance
      t.float :order_amount
      t.float :minimum_balance
      t.integer :portfolio_size
      t.float :reinvest_percent
      t.float :order_charge
      t.string :entry_slippage
      t.string :exit_slippage
      t.integer :log_level
      t.boolean :keep_tables
      t.datetime :job_started_at
      t.datetime :job_finished_at
    end
  end

  def self.down
    drop_table :sim_jobs
  end
end
