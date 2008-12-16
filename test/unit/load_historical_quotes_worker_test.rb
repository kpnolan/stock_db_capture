require File.dirname(__FILE__) + '/../test_helper'
require "#{RAILS_ROOT}/vendor/plugins/backgroundrb/backgroundrb.rb"
require "#{RAILS_ROOT}/lib/workers/load_historical_quotes_worker"
require 'drb'

class LoadHistoricalQuotesWorkerTest < Test::Unit::TestCase

  # Replace this with your real tests.
  def test_truth
    assert LoadHistoricalQuotesWorker.included_modules.include?(DRbUndumped)
  end
end
