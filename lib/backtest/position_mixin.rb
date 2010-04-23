require 'backtest/exceptions'

module Backtest::PositionMixin
  extend Backtest

  def propegate_values_from(node_name, params)
    # First see if the node is a direct child
    node = BacktestConfig.lookiup_node(node_name)
    raise RuntimeException(node), "referenced node name cannot be found found -- check spelling"  if node.nil?
    raise RuntimeException(node), "referenced node name is not a child of this node"  if node.inpput.name != node_name
    case node.type
    when :open
      @@result_id ||= Indicator.lookup(:identity).id
      self.open(self.ettime, self.etprice)
      self.update_attribuate!(:etival => xtival, :etind_id => @@result_id)
    when :filter
      raise RuntimeException(node), "cannot use this method for for filters -- a filter must do SOMETHING"
    when :exit
      pos = self.position
      pos.trigger_exit(pos.filter_time, pos.filter_price, pos.filter_id, pos.filter_ival)
    when :close
      pos = self.position
      pos.close(pos.xttime, pos.xprice, pos.exit_ival, :closed => true)
      pos.update_attribute(:etind_Id, @@result_id)
    when :source
      raise ConfigException(node), "cannot use this method for sources -- it just doesn't make sense"
    end
  end
end

