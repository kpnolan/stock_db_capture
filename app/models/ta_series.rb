# == Schema Information
# Schema version: 20090815165411
#
# Table name: ta_series
#
#  id         :integer(4)      not null, primary key
#  ticker_id  :integer(4)
#  ta_spec_id :integer(4)
#  stime      :datetime
#  value      :float
#  seq        :integer(4)
#

class TaSeries < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :ta_spec

  include GSL

  class << self
    def predict(ticker_id, indicator, date=Date.today, seq=480, params = { })
      params.reverse_merge! :time_period => 14
      ta = TaSpec.find_by_name_and_time_period(indicator, params[:time_period])
      series = find(:all, :conditions => ["ticker_id = ? and date(stime) = ?", ticker_id, date], :order => "stime, seq").map { |ts| [ts.seq, ts.value] }
      seq_vec = series.map(&:first).to_gv
      val_vec = series.map(&:last).to_gv
      inter, slope, cov00, cov01, cov11, chisq, status = GSL::Fit.linear(seq_vec, val_vec)
      raise Exception, "Non-zero status for GSL::Fit.linear" unless status.zero?
      GSL::Fit::linear_est(seq, inter, slope, cov00, cov01, cov11)
    end
  end
end
