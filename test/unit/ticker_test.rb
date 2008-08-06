require 'test_helper'

class TickerTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Ticker.new.valid?
  end
end
