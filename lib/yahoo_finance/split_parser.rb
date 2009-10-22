require 'nokogiri'
require 'open-uri'

module YahooFinance
  class SplitParser

    attr_reader :symbol, :options, :re

    def initialize(symbol, options={})
      @symbol = symbol
      @options= options
      @re = Regexp.new('\[(\d+):(\d+)\]')
    end

    def construct_url(symbol)
      "http://finance.yahoo.com/q/bc?s=#{symbol}&t=my"
    end

    def splits()
      url = construct_url(symbol.upcase)
      doc = Nokogiri::HTML(open(url))
      returning [] do |splits|
        doc.search("//table[@class='yfnc_datamodoutline1']//center/nobr").each do |node|
          puts "#{symbol} #{node.content}" if options[:debug]
          pair = node.content.split(' ')
          triple = pair.first.split('-')
          year = triple.third.to_i
          year = year <= 25 ? year + 2000 : year + 1900
          datestr = "#{year}-#{triple.second}-#{triple.first}"
          date = Date.parse(datestr)
          if (match = re.match(pair.last))
            from, to = match[1,2].map(&:to_i)
          else
            raise Exception, "Bad split ratio syntax: #{pair.last}"
          end
          splits << { :date => date, :from => from, :to => to }
        end
      end
    end
  end
end
