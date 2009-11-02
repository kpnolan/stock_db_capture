module LedgerTxnsHelper
  def ledger_txns_path
    objects_path
  end

  def ledger_txn_path(obj)
    object_path(obj)
  end
end
