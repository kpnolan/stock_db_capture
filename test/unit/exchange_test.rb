require 'test_helper'

class ExchangeTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Exchange.new.valid?
  end
end
