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

  class ReportGenerator < Subsystem

    attr_reader :prefix

    def initialize(sm, cm)
      super(sm, cm, self.class)
      @prefix = File.join(output_dir, (cval(:prefix) ? cval(:prefix)+'_' : cval(:position_table)+'_'))
    end

    def generate_reports()
      if cval(:output).include? 'summary'
        cols = SimSummary.columns.map(&:name)
        CSV.open(prefix+'sim_summary.csv', "w") do |csv|
          csv << [:day, :date, :held, :avail, :port_value, :cash_value, :opened, :closed, :total].map { |c| c.to_s.humanize.titleize }
          for row in SimSummary.all
            csv << (cols.map { |c| row.send(c) } << (row.portfolio_value + row.cash_balance))
          end
        end
      end

      if cval(:output).include? 'positions'
        cols = [:symbol, :entry_date, :exit_date, :entry_price, :exit_price, :quantity, :volume, :nreturn, :roi, :days_held]
        extra = { :entry_date => :to_date, :exit_date => :to_date }
        heading = cols.map { |c| c.to_s.humanize.titleize }
        CSV.open(prefix+'sim_positions.csv', "w") do |csv|
          csv << heading
          for row in SimPosition.all
            csv << cols.map { |c| extra[c] ? (val = row.send(c)) && val.send(extra[c]) : row.send(c) }
          end
        end
      end
    end
  end
end
