require 'faster_csv'

class ReportGenerator < Subsystem
  def initialize(sm, cm)
    super(sm, cm, self.class)
  end

  def generate_reports()
    if cval(:ouput).include? 'summary'
      prefix = cval(:prefix) ? cval(:prefix)+'_' : ''
      FasterCSV.open(prefix+'sim_summary', "w") do |csv|
        csv << [:day, :date, :held, :avail, :port_value, :cash_value, :opened, :closed, :total]
        for row in SimSummaries.all
          csv << row + row.portfolio_value + row.cash_balance
        end
      end
    end

    if cval(:ouput).include? 'positions'
      prefix = cval(:prefix) ? cval(:prefix)+'_' : ''
      cols = [:symbol, :entry_date, :exit_date, :entry_price, :exit_price, :quantity, :nreturn, :roi, :days_held]
      heading = cols.map { |c| c.t_s.humanize.titleize }
      FasterCSV.open(prefix+'sim_positions', "w") do |csv|
        csv << heading
        for row in SimPosition.all
          csv << cols.map { |c| row.send(c) }
        end
      end
    end
  end
end
