class CreateLedgerTxns < ActiveRecord::Migration
  def self.up
    create_table :ledger_txns, :force => true do |t|
      t.float    :amount
      t.datetime :date
      t.integer  :type
      t.integer  :order_id
      t.float    :balance
      t.string   :msg
    end
  end

  def self.down
    drop_table :ledger_txns
  end
end
