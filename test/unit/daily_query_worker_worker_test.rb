require File.dirname(__FILE__) + '/../test_helper'
require "#{RAILS_ROOT}/vendor/plugins/backgroundrb/backgroundrb.rb"
require "#{RAILS_ROOT}/lib/workers/daily_query_worker_worker"
require 'drb'

class DailyQueryWorkerWorkerTest < Test::Unit::TestCase

  # Replace this with your real tests.
  def test_truth
    assert DailyQueryWorkerWorker.included_modules.include?(DRbUndumped)
  end
end
