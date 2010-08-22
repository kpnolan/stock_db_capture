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
class TickersController < ApplicationController

  protect_from_forgery :except => [:index, :auto_complete_for_ticker_symbol]

#  auto_complete_for :ticker, :symbol

  make_resourceful do
    publish :xml, :attributes => [ :symbol, { :listing => [:name] } ]
    actions :all

    before :save do
      current_object.symbol.upcase!
    end
  end

  def find
    symbol = params[:ticker][:symbol]
    @current_objects ||= current_model.paginate(:all, :conditions => "symbol LIKE '#{symbol}%'", :page => params[:page], :per_page => 30, :include => [ :exchange, :current_listing] , :order => 'symbol')
    render :action => :index
  end

  def current_objects()
    @current_objects ||= current_model.paginate(:all, :page => params[:page], :per_page => 30, :include => [ :exchange, :current_listing] , :order => 'symbol')
  end

  def plot_daily
  end

  def plot_live
  end

  def plot_histogram
  end

end
