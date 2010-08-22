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

module Sim
  class PortfolioMgr < Subsystem

    attr_reader :min_balance, :reinvest_factor, :order_limit, :portfolio_size

    def initialize(sm, cm)
      super(sm, cm, self.class)
      @reinvest_factor = cval(:reinvest_percent) && cval(:reinvest_percent) / 100.0
      @portfolio_size = cval(:portfolio_size)
    end

    def post_dispatch_hook()
      @min_balance = minimum_balance()
      @order_limit = order_amount()
    end

    def open_position_count()
      SimPosition.open_position_count()
    end

    def mature_positions()
      SimPosition.exiting_positions(sysdate())
    end

    def num_vacancies()
      available_balance = current_balance() - min_balance
      if reinvest_factor && reinvest_factor > 0
        available_balance * reinvest_factor / order_limit
      elsif portfolio_size && portfolio_size > 0
        [portfolio_size - open_position_count(), available_balance / order_limit].min
      else
        0
      end
    end

    def market_value(date)
      sql = "select sum(close*quantity) from #{SimPosition.table_name} join daily_bars using(ticker_id) where bardate = '#{date.to_s(:db)}' and exit_date is null"
      SimPosition.connection.select_value(sql).to_f
    end
  end
end
