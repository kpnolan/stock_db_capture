#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
module Resourceful
  module Default
    module Actions
      def exits
        load_objects
        before :exits
        response_for :exits
        after :exits
      end
    end
  end
end

class WatchListsController < ApplicationController

  layout 'watch_list'

  attr_reader :current_objects

  make_resourceful do
    actions :all

    before :exits do
      self.sort_order ||=  'open_crossed_at desc, price'
      @current_objects = wl = WatchList.all(:conditions => 'opened_on is not null', :include => :ticker, :order => :opened_on)
      session[:prices] = wl.inject({}) { |h, obj| h[obj.id] = obj.price; h}
      session[:prev_prices] = session[:prices] if session[:prev_prices].nil? or session[:prev_prices].keys != session[:prices].keys
    end

    before :index do
      self.sort_order ||=  'open_crossed_at desc, price'
      @current_objects = wl = WatchList.find(:all, :include => :ticker, :conditions => 'opened_on is null', :order => sort_order)
      session[:prices] = wl.inject({}) { |h, obj| h[obj.id] = obj.price; h}
      session[:prev_prices] = session[:prices] if session[:prev_prices].nil? or session[:prev_prices].keys != session[:prices].keys
    end

    after :index, :exits do
      session[:prev_prices] = session[:prices]
    end

    before :destroy do
      positions = TdaPosition.find(:all, :conditions => { :watch_list_id => current_object.id } )
      positions.each do |position|
        position.update_attribute(:watch_list_id, nil)
      end
    end
  end

  def generate_entry_csv
    csv_string = WatchList.generate_entry_csv()
    send_data csv_string, :filename => "entry_watch_list-#{Date.today.to_formatted_s(:ymd)}.csv", :type => 'application/csv'
  end

  def generate_exit_csv
    csv_string = WatchList.generate_exit_csv()
    send_data csv_string, :filename => "exit_watch_list-#{Date.today.to_formatted_s(:ymd)}.csv", :type => 'application/csv'
  end

  def plot
   puts "echo plot.rt.snap('#{current_object.ticker.symbol}') | R --no-save"
    `echo "plot.rt.snap('#{current_object.ticker.symbol}')" | R --no-save`
    send_file File.join(RAILS_ROOT, 'Rplots.pdf')
  end

  def sort_order
    session[:watch_list_sort_order]
  end

  def sort_order=(str)
    session[:watch_list_sort_order] = str
  end

  def sort_by_time
    self.sort_order = 'open_crossed_at desc, price'
    render_js do |page|
      page.redirect_to :action => 'index'
    end
  end

  def sort_by_price
    self.sort_order = 'price, open_crossed_at desc'
    render_js do |page|
      page.redirect_to :action => 'index'
    end
  end
end
