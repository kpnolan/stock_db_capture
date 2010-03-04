# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'load_bars'
require 'bar_utils'
require 'db_maintenance'

extend BarUtils
extend DbMaintenance

namespace :active_trader do

  desc "Purge DB"
  task :purge_db => :environment do
    logger = init_logger(:purge_db)
    purge_db(logger)
  end

  desc "Output DB tables (bziped)"
  task :output_tables => :environment do
    output_tables()
  end
end
