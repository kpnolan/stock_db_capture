# == Schema Information
# Schema version: 20090425175412
#
# Table name: positions
#
#  id               :integer(4)      not null, primary key
#  ticker_id        :integer(4)
#  entry_date       :datetime
#  exit_date        :datetime
#  entry_price      :float
#  exit_price       :float
#  num_shares       :integer(4)
#  stop_loss        :string(255)
#  strategy_id      :integer(4)
#  days_held        :integer(4)
#  nomalized_return :floaT              # FIXME! spelling
#  risk_factor      :float
#  week             :integer(4)
#  scan_id          :integer(4)
#
require 'rubygems'
require 'ruby-debug'
class Position < ActiveRecord::Base

  extend TradingCalendar

  belongs_to :ticker
  has_and_belongs_to_many :strategies

  def self.open(population, strategy, ticker, entry_date, entry_price)
    week = entry_date.to_date.cweek
    create!(:scan_id => population.id, :strategy_id => strategy.id, :ticker_id => ticker.id,
            :entry_price => entry_price, :entry_date => entry_date, :num_shares => 1, :week => week)
  end

  def close_at_max(options={})
    options.reverse_merge! :method => :sql
    hold_time = options[:hold_time] # i.e. 3..10 days
    start_date = entry_date.to_date + hold_time.begin
    end_date = Position.trading_to_calendar(start_date, hold_time.end-hold_time.begin)

#    ts = Timeseries.new(ticker_id, start_date..end_date, 1.day,
#                        :populate => true, :pre_buffer => false)
#    dummy, idx, vecs = ts.rvi(:result => :raw, :noplot => true)
#    raise ArgumentError.new("RVi: returned #{vec.length}, expected 1") unless vecs.length == 1
#    risk = vecs.first.average
    risk = nil
    if options[:method] == :sql
      max_adj_close, exit_date = DailyClose.max_between(:adj_close, ticker_id, start_date..end_date)
      days_held = Position.trading_day_count(entry_date.to_date, exit_date.to_date)
      nreturn = ((max_adj_close - entry_price) / entry_price) / days_held
    else
      adj_close_vec = ts.adj_close
      max_adj_close = adj_close_vec.max
      days_held = adj_close_vec.index(max_adj_close)
      exit_date = ts.index2time(index).to_date
      logrs = ts.logr[0..index].sum
      nreturn = Math.exp(logrs)
    end
    update_attributes!(:exit_price => max_adj_close, :exit_date => exit_date,
                       :days_held => days_held, :nreturn => nreturn,
                       :risk_factor => risk)
  end

  def close_at_days_held(day_number)
    date = Position.trading_to_calendar(entry_date.to_date, day_number)
    dc = DailyClose.first(:conditions => { :ticker_id => ticker_id, :date => date } )
    if dc
      nreturn = ((dc.adj_close - entry_price) / entry_price) / day_number
      update_attributes!(:exit_price => dc.adj_close, :exit_date => date,
                         :days_held => day_number, :nreturn => nreturn,
                         :risk_factor => nil)
    else
      puts "Cannot find Daily Close for #{ticker.symbol} on #{date}"
    end
  end
  def close_at(options)
    begin
      indicator = options[:indicator]
      params = options[:params]
      ts = Timeseries.new(ticker_id, entry_date..(entry_date+4.months), 1.day,
                          :populate => true, :pre_buffer => false)
      memo = ts.send(indicator, params.merge(:noplot => true, :result => :memo))
      indexes = memo.over_threshold(params[:threshold], :real)
      if indexes.empty?
        update_attributes!(:exit_price => nil, :exit_date => nil,
                           :days_held => nil, :nreturn => nil,
                           :risk_factor => nil)
      else
        index = indexes.first
        price = ts.value_at(index, :close)
        edate = entry_date.to_date
        xdate = ts.index2time(index)
        days_held = Position.trading_day_count(edate, xdate)
        nreturn = days_held.zero? ? 0.0 : ((price - entry_price) / entry_price) / days_held
        puts "#{edate}\t#{days_held}\t#{entry_price}\t#{price}\t#{nreturn*100.0}"
        update_attributes!(:exit_price => price, :exit_date => xdate,
                           :days_held => days_held, :nreturn => nreturn,
                           :risk_factor => nil)
      end
    rescue Exception => e
      puts "Exception Raised: #{e.to_s} skipping closure}"
      puts self.inspect
    end
  end
end
