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
module WatchListsHelper

  attr_reader :exit_vec

  STATUS_COLORS = {
    'W' => '#f8cdb9',
    'O' => '#f8a882',
    'C' => '#f8783d',
    'S' => '#75391d',
  }

  def price_color(watch_list)
    if session[:prices][watch_list.id].nil? or session[:prev_prices][watch_list.id].nil?
      'green'
    else
      session[:prices][watch_list.id] >= session[:prev_prices][watch_list.id] ? 'green' : 'red'
    end
  end

  def percentage_color(watch_list)
    watch_list.target_percentage && (watch_list.target_percentage > 0 ? 'red' : 'green') || 'black'
  end

  def exiting_objects
    @exit_vec ||= WatchList.find(:all, :include => :tda_position,
                                 :conditions => 'opened_on IS NOT NULL', :order => 'opened_on')
    session[:prices] = exit_vec.inject({}) { |h, obj| h[obj.id] = obj.price; h}
    session[:prev_prices] = session[:prices] if session[:prev_prices].nil? or session[:prev_prices].keys != session[:prices].keys
    exit_vec
  end

  def sort_by_price
    remote_function :url => { :action => :sort_by_price },
                    :failure => "alert('HTTP Error ' + request.status + '!')"
  end

  def sort_by_time
    remote_function :url => { :action => :sort_by_time },
                    :failure => "alert('HTTP Error ' + request.status + '!')"
  end

  def status_color(obj)
    STATUS_COLORS[obj.status()]
  end

  def watch_lists_path
    objects_path
  end

  def watch_list_path(obj)
    object_path(obj)
  end
end
