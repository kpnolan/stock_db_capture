# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'ruby-debug'

module TradingCalendar

  DATEFMT1 = /(\d{1,2})[-\/](\d{1,2})[-\/](\d{2,4})/
  DATEFMT2 = /(\d{1,2})[-\/](\d{1,2})/

  EPOCH = Time.local(1980, 1, 1, 6, 30)             # Jan 1, 1980 6:30AM
  EPOCH_END = Time.local(2010,12, 31, 6, 30)        # Dec 31, 2010 6:30AM
  YEAR_SECONDS = 60*60*24*365
  LEAP_SECONDS = 60*60*24*366
  DST_CORRECTION = 60*60

  #
  # Initialize the holidays hash once the first time this module is
  # extended into a class or module
  #
  def TradingCalendar.extend_object(o)
    @@holidays ||= holiday_init()
    @@calendar ||= calendar_init()
    super
  end
  #
  # Initialize the holidays has with the holidays represented in shorthand in the
  # HOLIDAYS table. Holidays are record from 2000 to 2010
  #
  def TradingCalendar.holiday_init()
    holidays = {}
    Holidays::FROM1980.each do |holiday|
      year, month, day = holiday.split('-').map(&:to_i)
      holidays[Time.local(year, month, day, 6, 30).to_i] = true
    end
    Holidays::FROM2000.each_pair do |year, dates|
      for date in dates
        mon, day = date.split('/')
        holidays[Time.local(year, mon.to_i, day.to_i, 6, 30).to_i] = true
      end
    end
    holidays
  end

  #
  # Initialize the Trading Calendar that maps Dates, encoded as Times, to the trading day index based
  # on the Trading Calendar Epoch of 1/1/1980. A reverse hash is also created to map indexes to Dates
  #
  def TradingCalendar.calendar_init
    date_seconds = EPOCH.to_i
    epoch_end_seconds = EPOCH_END.to_i
    day_index = 0
    calendar = {}
    @@invert_calendar = {}
    begin
      year_seconds = Time.at(date_seconds).year % 4 != 0 ? YEAR_SECONDS : LEAP_SECONDS
      (0...year_seconds).step(1.day) do |seconds|
        current_seconds = date_seconds + seconds
        current_seconds -= DST_CORRECTION if Time.at(current_seconds).dst?
        if trading_day?(Time.at(current_seconds))
          calendar[current_seconds] = day_index
          @@invert_calendar[day_index] = current_seconds
          day_index += 1
        else
          calendar[current_seconds] = day_index
        end
      end
      date_seconds += year_seconds
    end while date_seconds < epoch_end_seconds
    return calendar
  end

  def TradingCalendar.trading_day?(time)
    1 << time.wday | 0x3E == 0x3E && !@@holidays[time.to_i]
  end

  def time2index(time, raise_exception=false)
    index = @@calendar[time.to_i]
    raise ArgumentError, "#{time.to_date.to_s(:db)} not contained in Trading Calendar" if index.nil? and raise_exception
    index
  end

  def index2time(index, raise_exception=true)
    time = Time.at(@@invert_calendar[index])
    raise ArgumentError, "Trading Day Index #{index} not found in Trading Calendar" if time.nil? and raise_exception
    time
  end

  #
  # true if weekday is between 1 through 5 and not a holiday
  #
  def trading_day?(time)
    1 << time.wday | 0x3E == 0x3E && !@@holidays[time.to_i]
  end
  #
  # returns and array of times (6:30AM local) of the trading dates (inclusive by default) between two times
  #
  def trading_days(time1, time2, inclusive=true)
    validate_times(time1, time2)
    sec1 = time1.to_i
    sec2 = time2.to_i
    times = returning [] do |timevec|
      (sec1..sec2).step(1.day) do |seconds|
        time = Time.at(seconds)
        timevec << time if trading_day?(time)
      end
    end
    # The range was inclusive, but the iteration was exclusive
    #times << time2 if inclusive and trading_day?(time2)
    times
  end
  #
  # Number of trading days in the given year. If year is less than 25, add 2000 to the year
  #
  def trading_count_for_year(year)
    year = year + 2000 if year < 25
    start_date = Time.local(year, 1, 1)
    end_date = Time.local(year, 12, 31)
    trading_day_count(start_date, end_date)
  end
  #
  # returns the date which is number trading days from the first arg (date or time)
  # The number can be negative in which case the date is before the given date
  #
  def trading_date_from(date_or_time, number)
    return date_or_time if number.zero?
    time = date_or_time.to_time.change(:hour => 6, :min => 30)
    base_index = time2index(time)
    offset_time = index2time(base_index+number)
    date_or_time.is_a?(Date) ? offset_time.to_date : offset_time
  end

  #
  # return the total bars between the two days, multiplied by the given
  # bars_per_day
  #
  def total_bars(date1, date2, bars_per_day=1)
    trading_day_count(date1, date2) * bars_per_day
  end

  #
  # return the number of tradings days between the two dates (inclusive by default)
  # FIXME this seem to be
  #
  def trading_day_count(date1, date2, inclusive=true)
    index1 = time2index(date1.to_time.change(:hour => 6, :min => 30), true)
    index2 = time2index(date2.to_time.change(:hour => 6, :min => 30), true)
    index2 - index1 + (inclusive ? 1 : 0)
  end

  #
  # return the number of tradings days (exclusive) between the two dates
  #
  def trading_days_between(date1, date2)
    trading_day_count(date1, date2, false)
  end

  #
  # Convert an Array of Time/Dates to an Array of Ranges of consecutive trading days
  #
  def to_ranges(date_or_time_array)
    array = date_or_time_array.compact.uniq.sort
    ranges = []
    if !array.empty?
      # Initialize the left and right endpoints of the range
      left, right = array.first, nil
      array.each do |obj|
        # If the right endpoint is set and obj is not equal to right's successor
        # then we need to create a range.
        if right && obj != trading_date_from(right, 1)
          ranges << Range.new(left,right)
          left = obj
        end
        right = obj
      end
      ranges << Range.new(left,right)
    end
    ranges
  end
  #
  # return the zero-based index of the time given the period in minutes of
  # a trading day. For example index of 9:30 would be 6 if the period was 30 minutes
  #
  def ttime2index(time, period)
    tstr = time.strftime("%m/%d/%Y %H:%M %z")
    d = Date._strptime(tstr, "%m/%d/%Y %H:%M")
    t = Time.local(d[:year], d[:mon], d[:mday], 6, 30, 0, 0)
    delta = time - t
    index = (delta / resolution).to_i
  end

  #
  # tries to parse a date given the following formats
  #    M/D/YY or MM/DD/YY or MM/DD/YYYY or MM/DD or M/D
  # or permuations of the above, using regular expression (fast). If the date doesn't match
  # any of the given formats it is pased on to Date.parse which does
  # a more thorough (and much slower) job of parsing the given date string
  #
  def normalize_date(date)
    if m = DATEFMT1.match(date)
      y = m[2].to_i
      year = y > 1900 ? y : y < 25 ? y+2000 : y+1900
      year = m[3].length == 2 ? 2000 + m[2].to_int : m[2].to_i
      mon = m[1].to_i
      day = m[2].to_i
      Time.local(year, mon, day)
    elsif m =  DATEFMT2.match(date)
      year = 2009
      mon = m[1].to_i
      day = m[2].to_i
      Time.local(year, mon, day)
    else
      raise ArgumentError, "unknown date format #{date}"
    end
  end

  def validate_times(*times)
    times.each do |time|
      raise ArgumentError, "time for date must be given at local time midnight" unless !time.gmt? && time.hour == 6 && time.min == 30
    end
  end

  #
  # This routine does a whole lot of process to make the entry of dates user friendly
  # so that a timeseries can be create with Dates/Times like
  # ts = Timeeries.new('IBM'), 1.month.ago)             # one month ago upto today
  # ts = Timeeries.new('IBM'), Date.today, -2.months)
  # ts = Timeeries.new('IBM'), 1.year.ago, 252) # Fixnum as date2 are treated as trading days
  # ts = Timeeries.new('IBM'), 1.month.ago, 10) # Fixnum as date2 are treated as trading days
  # ts = Timeeries.new('IBM'), Date.today, nil, 30.minutes) # 30 minute bars for today
  # ts = Timeeries.new('IBM'), 1.week.ago, nil, 1.minute) # 1 minute bars for for last week (max history)
  # ts = Timeeries.new('IBM'), Date.today, nil, 1.minute) # 1 minute bars for today
  # ts = Timeeries.new('IBM'), '1/1', Date.today) # All 1 day bars for 2009 (so far)
  #
  def normalize_dates(arg1, arg2, res)
    dates = case
            when arg1.is_a?(Date) && arg2.is_a?(Date) then  [arg1, arg2]
            when arg1.is_a?(String) && arg2.is_a?(String) then  [normalize_date(arg1), normalize_date(arg2)]
            when arg1.is_a?(Date) && arg2.is_a?(Fixnum) && arg2 < 252 && arg2 >= 0 then arg1..trading_date_from(arg1, arg2)
            when arg1.is_a?(Date) && arg2.is_a?(Fixnum) && arg2 < -252 then arg1..(date+arg2)
            end
  end
end
