# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on.
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
   config.load_paths += %W( #{RAILS_ROOT}/lib/workers )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'Eastern Time (US & Canada)'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_stock_db_capture_session',
    :secret      => 'b44cd5c428ffef1c44c1bb88dccf6cea79dbd7db9434d380391263a6582f5a177473c829b2fc3a0ed9dc02bf5179e3e397f860ccaa1027754623a5358d8830f0'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
end

require 'smart_form_builder'
#require 'memcached'
require 'will_paginate'
require 'gsl'
require 'talib'
require 'yaml'
require 'convert_talib_meta_info'
require 'timeseries'
require 'excel_simulation_dumper'
require 'visualize_entry'
require 'ruby-debug'

include TradingCalendar
include ExcelSimulationDumper
include VisualizeEntry

# ARGV is empty when launching from script/console and script/server (and presumabily passenger) AND
# ARGV[0] contains the name of the rake task otherwise. Since, at this point, we don't have any rake
# tasks the use Talib functions, we will skip this whole initialization block for rake tasks.
if ARGV.empty? || (ARGV[0] =~ /active_trader/).nil?
  Talib.ta_initialize();

  TALIB_META_INFO_HASH = YAML.load_file("#{RAILS_ROOT}/config/ta_func_api.yml")
  USER_META_INFO_HASH = YAML.load_file("#{RAILS_ROOT}/config/user_func_api.yml")
  TALIB_META_INFO_HASH.underscore_keys!
  USER_META_INFO_HASH.underscore_keys!
  TALIB_META_INFO_DICTIONARY = ConvertTalibMetaInfo.import_functions(TALIB_META_INFO_HASH['financial_functions']['financial_function'])
  TALIB_META_INFO_DICTIONARY.merge!(ConvertTalibMetaInfo.import_functions(USER_META_INFO_HASH['financial_functions']['financial_function']))
  #ts(:rri, Date.civil(2008, 7, 15)..Date.civil(2008,12, 15), 1.day)

  #ts(:msft, Date.parse('03/02/2009')..Date.parse('3/31/2009'), 30.minutes, :pre_buffer => 0, :post_buffer => 0, :populate => true)

  def lookup(symbol, start_date, end_date=nil, options={})
    options.reverse_merge! :interval => 1.day.seconds
    begin
      $qs ||= TdAmeritrade::QuoteServer.new
      start_date = start_date.is_a?(Date) ? start_date : Date.parse(start_date)
      end_date = end_date.nil? ? start_date : end_date.is_a?(Date) ? end_date : Date.parse(end_date)
      if options[:interval] == 1.day.seconds
        td = trading_days(start_date..end_date).length
        puts "#{td} trading days in period specified"
        $qs.dailys_for(symbol, start_date, end_date, options) #unless td.zero?
      else
        period = options[:interval] < 60 ? options[:interval] : options[:interval]/60
        $qs.intraday_for(symbol, start_date, end_date, period, options)
      end
    rescue Net::HTTPServerException => e
      puts "No Data Found for #{symbol}" if e.to_s.split.first == '400'
    rescue Exception => e
      puts e.to_s
    end
  end
end

#puts "RAILS_ENV: #{RAILS_ENV}"
#puts "ENV['RAILS_ENV']: #{ENV['RAILS_ENV']}"

#$cache = Memcached.new(["kevin-laptop:11211:8", "amd64:11211:2"], :support_cas => true, :show_backtraces => true)
#$cache = Memcached.new(["amd64:11211:2"], :support_cas => true, :show_backtraces => true)



