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

require 'nokogiri'
require 'open-uri'

module YahooFinance
  class SplitParser

    attr_reader :symbol, :options, :re, :logger

    def initialize(symbol, options={})
      @symbol = symbol
      @options= options
      @logger = options[:logger]
      @re = Regexp.new('\[(\d+):(\d+)\]')
    end

    def construct_url(symbol)
      ("http://finance.yahoo.com/q/bc?s=#{symbol}&t=my")
    end

    def splits()
      url = construct_url(symbol.upcase)
      begin
        doc = Nokogiri::HTML(open(url))
      rescue Exception => e
        logger.error("#{e.class}: #{e.to_s} on #{url}") if logger
        retry unless url.include? ' '
      end
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
