require 'faster_csv'

module Sim

  class ReportGenerator < Subsystem

    attr_reader :prefix

    def initialize(sm, cm)
      super(sm, cm, self.class)
      @prefix = File.join(RAILS_ROOT, 'log', (cval(:prefix) ? cval(:prefix)+'_' : ''))
    end

    def generate_reports()
      if cval(:output).include? 'summary'
        cols = SimSummary.columns.map(&:name)
        FasterCSV.open(prefix+'sim_summary.csv', "w") do |csv|
          csv << [:day, :date, :held, :avail, :port_value, :cash_value, :opened, :closed, :total].map { |c| c.to_s.humanize.titleize }
          for row in SimSummary.all
            csv << (cols.map { |c| row.send(c) } << (row.portfolio_value + row.cash_balance))
          end
        end
      end

      if cval(:output).include? 'positions'
        cols = [:symbol, :entry_date, :exit_date, :entry_price, :exit_price, :quantity, :nreturn, :roi, :days_held]
        extra = { :entry_date => :to_date, :exit_date => :to_date }
        heading = cols.map { |c| c.to_s.humanize.titleize }
        FasterCSV.open(prefix+'sim_positions.csv', "w") do |csv|
          csv << heading
          for row in SimPosition.all
            csv << cols.map { |c| extra[c] ? (val = row.send(c)) && val.send(extra[c]) : row.send(c) }
          end
        end
      end
    end
  end
end
