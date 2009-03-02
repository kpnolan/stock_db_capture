class CreatePositions < ActiveRecord::Migration
  def self.up
    create_table :positions, :force => true do |t|
      t.integer     :portfolio_id
      t.integer     :ticker_id
      t.boolean     :open
      t.datetime    :entry_date
      t.datetime    :exit_date
      t.float       :entry_price
      t.float       :exit_price
      t.integer     :num_shares
      t.integer     :contract_type_id
      t.integer     :side
      t.string      :stop_loss
      t.timestamps
    end
  end

  def self.down
    drop_table :positions
  end
end
