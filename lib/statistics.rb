require 'rubygems'
require 'pp'
require 'ruby-debug'
require 'gsl'

module StatisticsSet
  ATTRS = [ :open, :high, :low, :close, :volume, :adj_close ]

  class StatSet

    SIMPLE_VALS = [:mean, :min, :max, :stddev, :absdev, :skew, :kurtosis]
    COMPLEX_VALS = [ :slope, :yinter, :cov00, :cov01, :cov11, :chisq ]


    attr_accessor :samples, :sample_count
    attr_accessor :mean, :min, :max, :stddev, :absdev, :skew, :kurtosis
    attr_accessor :slope, :yinter, :cov00, :cov01, :cov11, :chisq
    attr_accessor :unit_vector

    def initialize(samples, &block)
      self.samples = GSL::Vector.alloc(samples)
      self.sample_count = samples.length
      self.unit_vector = GSL::Vector.linspace(0, sample_count-1, sample_count-1)
      if block_given?
        yield self
      end
    end

    def compute_min
      self.min = samples.min
    end

    def compute_max
      self.max = samples.max
    end

    def compute_mean
      self.mean = samples.mean
    end

    def compute_stddev
      self.stddev = samples.sd(mean)
    end

    def compute_absdev
      self.absdev = samples.absdev(mean)
    end

    def compute_skew
      self.skew = samples.skew
    end

    def compute_kurtosis
      self.kurtosis = samples.kurtosis
    end

    def compute_regression
      self.yinter, self.slope, self.cov00, self.cov01, self.cov11, self.chisq = GSL::Fit::linear(unit_vector, samples)
    end

    def compute
      SIMPLE_VALS.each do |fcn|
        send("compute_#{fcn}")
      end
      compute_regression
      self
    end

    def to_hash
      all_vals = SIMPLE_VALS + COMPLEX_VALS + [:sample_count]
      all_vals.inject({}) { |h, k| h[k] = send(k); h }
    end
  end

  def self.generate(tickers)
    tickers.each do |ticker|
      t = Ticker.first(:conditions => { :symbol => ticker })
      if t and not (rows = DailyClose.all(:conditions => { :ticker_id => t.id }, :order => 'date')).empty?
        ATTRS.each do |attr|
          sample_vec = rows.collect(&attr)
          StatSet.new(sample_vec) do |ss|
            ss.compute()
            StatValue.create_row(attr.to_s, t, rows.first.date, rows.last.date, ss.to_hash)
          end
        end
      end
    end
  end
end
