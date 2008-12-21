require File.dirname(__FILE__) + '/../test_helper'
require "#{RAILS_ROOT}/vendor/plugins/backgroundrb/backgroundrb.rb"
require "#{RAILS_ROOT}/lib/workers/rail_time_quote_worker"
require 'drb'

class RailTimeQuoteWorkerTest < Test::Unit::TestCase

  # Replace this with your real tests.
  def test_truth
    assert RailTimeQuoteWorker.included_modules.include?(DRbUndumped)
  end
end
