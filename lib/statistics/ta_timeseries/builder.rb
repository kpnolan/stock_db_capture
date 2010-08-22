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

module Statistics
  module TaTimeseries
    class TitsException < Exception
      def initialize(msg)
        super(msg)
      end
    end

    class Builder

      attr_reader :name, :options, :indicators

      def initialize(name, options={ })
        @name = name
        @options = options
        @indicators = []
      end

      def indicator(name, options)
        raise TitsException, "#{name} is not a support method of Timeseries" unless Timeseries.instance_methods.include? name.to_s
        raise TitsException, 'option :time_period missing' unless options.has_key? :time_period

        ind = TaSpec.create_spec(name, options[:time_period])

        @indicators << ind
      end
    end
  end
end
