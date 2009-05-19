require 'tda2ruby'
require 'rubygems'
require 'ruby-debug'

module TdAmeritrade

  class QuoteServer

    include Tda2Ruby

    attr_accessor :options, :bars

    def initialize(options={})
      options.reverse_merge! :login => 'LWSG', :source => :file, :filename => 'PriceHistory(4)', :dir => '/home/kevin/Downloads'
      @options = options
      @bars = []
    end

    def retrieve_quotes_from_file()
      GC.disable
      buff = IO.read(File.join(options[:dir], options[:filename]))
      symbol_count, symbol, bar_count = parse_header(buff)
      bar_count.times do
        bar_ary = parse_bar(buff)
        bars.push(bar_ary)
      end
      GC.start
      for bar in bars
        puts %Q(#{bar.join("\t")})
      end
      nil
    end
  end
end
