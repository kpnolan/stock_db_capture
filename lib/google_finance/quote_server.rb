# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'net/http'
require 'date'
require 'ruby-debug'

module GoogleFinance

  DEFAULT_READ_TIMEOUT = 5
  MONTHS = ['Jan', 'Fef','Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  COLUMN_ORDER = [ :date, :opening, :high, :low,  :close, :volume ]
  TYPE_ORDER =   [ :to_s, :to_f, :to_f, :to_f, :to_f,  :to_i ]

  class QuoteServer

    attr_reader :options, :logger

    def initialize(options={})
      @options = options
      @logger = options[:logger]
    end

    def dailys_for(symbol, start_date, end_date, options={})
      ticker = Ticker.lookup(symbol)
      exch = ticker.exchange.symbol == 'NasdaqNM' ? 'NASDAQ' : ticker.exchange.symbol
      return [] unless exch == 'NASDAQ' or exch == 'NYSE' or exch == 'PCX'

      begin
        bars = GoogleFinance.retrieve_raw_historical_quotes(symbol, exch, start_date, end_date)
      rescue Exception => e
        if logger
          logger.error e.to_s
        else
          puts e.to_s
        end
        return []
      end
      returning [] do |table|
        bars.each do |bar|
          type_vec = TYPE_ORDER.dup
          table << bar.map! { |el| el.send(type_vec.shift) }
        end
      end
    end
  end

  class << self
    def parse_date_to_Date( date_str )
      return Date.parse(date_str)
    end

    def date_to_Date
      return Date.parse( @date )
    end

    def retrieve_raw_historical_quotes(symbol, exchange, start_date, end_date)
      #http://www.google.com/finance/historical?q=NASDAQ:GOOG&output=csv
      #http://www.google.com/finance/historical?q=NYSE:MO&startdate=Sep+1%2C+2007&enddate=Sep+20%2C+2007&output=csv

      return [] if start_date > end_date

      host = 'www.google.com'
      begin
        Net::HTTP.start(host, 80 ) do |http|
          query = "/finance/historical?q=#{exchange}:#{symbol}" +
          "&startdate=#{MONTHS[start_date.month-1]}+#{start_date.mday}%2C+#{start_date.year}" +
          "&enddate=#{MONTHS[end_date.month-1]}+#{end_date.mday}%2C+#{end_date.year}&output=csv"
          response = http.get( query )

          case response
          when Net::HTTPSuccess, Net::HTTPRedirection
            #puts "#{response.body}"
            body = response.body.chomp

            # If we don't get the first line like this, there was something
            # wrong with the data (404 error, new data formet, etc).
            return [] if body !~ /Date,Open,High,Low,Close,Volume/

            # Parse into an array of arrays.
            rows = CSV.parse( body )
            # Remove the first array since it is just the field headers.
            rows.shift
            #puts "#{rows.length}"

            return rows
          else
            response.error!
          end
        end
      rescue Timeout::Error
        retry
      end
    end

    def get_historical_quotes(symbol, start_date, end_date)
      rows = []
      rowct = 0
      gotchunk = false
      #
      # Yahoo is only able to provide 200 data points at a time for Some
      # "international" markets.  We want to download all of the data
      # points between the start_date and end_date, regardless of how many
      # 200 data point chunks it comes in.  In this section we download
      # as many chunks as needed to get all of the data points.
      #
      begin
        gotchunk = false
        r = retrieve_raw_historical_quotes( symbol, start_date, end_date )
        if block_given?
          # If we were given a block, yield to it for every row of data
          # downloaded.
          r.each { |row| yield row }
        else
          rows += r
        end

        # Is this a chunk?
        if r.length == 200
          # Adjust the end_date for when we retrieve the next chunk.
          end_date = parse_date_to_Date( r.last[0] ) - 1
          # Marke this as a chunk so do the download again with the new end_date.
          gotchunk = true
        end

      end while gotchunk

      if block_given?
        # If we have already yielded to every row, just return nil.
        return nil
      else
        # Otherwise return the big array of arrays.
        rows
      end
    end
  end
end



