# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module TradingCalendar
    HOLIDAYS = { 2000 => ['1/17', '2/21', '4/21', '5/29', '7/4', '9/4',  '11/23', '12/25' ],
                 2001 => ['1/1', '1/15', '2/19', '4/13', '5/28', '7/4', '9/3', '9/11', '9/12', '9/13', '9/14',  '11/22', '12/25' ],
                 2002 => ['1/1', '1/21', '2/18', '3/29', '5/27', '7/4', '9/2',  '11/28', '12/25' ],
                 2003 => ['1/1', '1/20', '2/17', '4/18', '5/26', '7/4', '9/1',  '11/27', '12/25' ],
                 2004 => ['1/1', '1/19', '2/16', '4/9',  '5/31', '6/11', '7/5', '9/6',  '11/25', '12/24' ],
                 2005 => ['1/17', '2/21', '3/25', '5/30', '7/4', '9/5',  '11/24',  '12/26' ],
                 2006 => ['1/2', '1/16', '2/20', '4/14', '5/29', '7/4', '9/4',  '11/23', '12/25' ],
                 2007 => ['1/1', '1/2', '1/15', '2/19', '4/6',  '5/28', '7/4', '9/3',  '11/22', '12/25' ],
                 2008 => ['1/1', '1/21', '2/18', '3/21', '5/26', '7/4', '9/1',  '11/27', '12/25' ],
                 2009 => ['1/1', '1/19', '2/16', '4/10', '5/25', '7/3', '9/7',  '11/26', '12/25' ],
                 2010 => ['1/1', '1/18', '2/15', '4/2',  '5/31', '7/5', '9/6',  '11/25', '12/25' ] }

  DATEFMT1 = /(\d{1,2})[-\/](\d{1,2})[-\/](\d{2,4})/
  DATEFMT2 = /(\d{1,2})[-\/](\d{1,2})/

  def holidays()
    if @holidays.nil?
      @holidays = {}
      HOLIDAYS.each_pair do |year, dates|
        for date in dates
          @holidays[Date.parse("#{date}/#{year}")] = true
        end
      end
    end
    @holidays
  end

  def trading_day?(date)
    wday = date.to_time.wday
    wday != 0 && wday != 6 && !holidays[date]
  end

  def trading_days(date_range)
    date_range.to_a.select do |date|
      wday = date.to_time.wday
      wday != 0 && wday != 6 && !holidays[date]
    end
  end

  def trading_count_for_year(year)
    year = year + 2000 if year < 2000
    start_date = Date.civil(year, 1, 1)
    end_date = Date.civil(year, 12, 31)
    trading_day_count(start_date, end_date)
  end

  def trading_days_for_year(year)
    year = year + 2000 if year < 2000
    start_date = Date.civil(year, 1, 1)
    end_date = Date.civil(year, 12, 31)
    trading_days(start_date..end_date)
  end

  def trading_days_from(date, number)
    date = date.to_date
    return [ date ] if number == 0
    if number < 0
      dir = -1
      number = -number
    else
      dir = 1
    end
    trading_days = [ ]
    calendar_days = dir
    while trading_days.empty? || trading_days.length < number
      next_date = date + calendar_days
      case
      when [0,6].include?(next_date.to_time.wday) : calendar_days += dir
      when holidays[next_date] : calendar_days += dir
      else
        trading_days << next_date
        calendar_days += dir
      end
    end
    return trading_days
  end

  def total_bars(date1, date2, bars_per_day=1)
    trading_day_count(date1, date2) * bars_per_day
  end

  def trading_day_count(date1, date2)
    trading_days(date1.to_date..date2.to_date).length
  end

  # FIXME these routines ore woefully inefficient. They make arrays and then take the lenght, that's fine if you
  # FIXME the array, but what if you only want a count?
  def trading_days_between(date1, date2)
    trading_days(date1.to_date..date2.to_date).length-1
  end

  def format_dates_where_clause(dates)
    " IN ('#{dates.join("',' ")}' )"
  end

  def trading_to_calendar(start_date, day_count)
    trading_days_from(start_date, day_count).last
  end

  def ttime2index(time, resolution)
    tstr = time.strftime("%m/%d/%Y %H:%M %z")
    d = Date._strptime(tstr, "%m/%d/%Y %H:%M")
    t = Time.local(d[:year], d[:mon], d[:mday], 6, 30, 0, 0)
    delta = time - t
    index = (delta / resolution).to_i
  end

  def normalize_date(date)
    return date unless date.is_a? String
    if m = DATEFMT1.match(date)
      y = m[2].to_int
      year = y > 1900 ? y : y < 25 ? y+2000 : y+1900
      year = m[3].length == 2 ? 2000 + m[2].to_int : m[2].to_int
      mon = m[1].to_i
      day = m[2].to_i
      Date.civil(year, mon, day)
    elsif m =  DATEFMT2.match(date)
      year = 2009
      mon = m[1].to_i
      day = m[2].to_i
      Date.civil(year, mon, day)
    else
      Date.parse(date)
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
            when arg1.is_a?(Date) && arg2.is_a?(Fixnum) && arg2 < 252 && arg2 >= 0 then arg1..trading_days_from(arg1, arg2).last
            when arg1.is_a?(Date) && arg2.is_a?(Fixnum) && arg2 < -252 then arg1..(date+arg2)
            end
  end
end
