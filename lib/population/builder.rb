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

module Population

  extend TradingCalendar

  class BuilderException < Exception
    def initialize(name, msg)
      super("Problem with statement named: #{name}: #{msg}")
    end
  end

  class Builder

    attr_reader :options

    def initialize(options)
      @options = options
      @scans = []
    end

    def find_scan(name)
      @scans.find { |tuple| tuple.first == name }
    end

    def prepare_attributes(options)
      cols = Scan.content_columns.map { |c| c.name.to_sym }
      options[:start_date] = options[:start_date].to_date
      options[:end_date] = options[:end_date].to_date
      options[:table_name] = 'daily_bars' if options[:table_name].nil?
      options[:prefetch] = options[:prefetch].to_i if options[:prefetch].is_a?(Numeric)
      options[:count] = options[:count].to_i if options[:count].is_a?(Numeric)
      options.reject { |key, value| ! cols.include? key }
    end

    def scan(name, options={})
      options.reverse_merge! :table_name => 'daily_bars'
      #begin
        name = name.to_s.downcase
        if (scan = Scan.find_by_name(name))
          attrs = prepare_attributes(options)
          scan.update_attributes!(attrs)
          @scans << scan
        else
          attrs = prepare_attributes(options)
          scan = Scan.create!({:name => name}.merge(options))
          @scans << scan
        end
      #rescue => e
      #  raise BuilderException.new(name, e.message)
      #end
    end
  end
end
