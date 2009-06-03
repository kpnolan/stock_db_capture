module TradingCalendar
    HOLIDAYS = { 2000 => ['1/1', '1/17', '2/21', '5/29', '7/4', '9/4',  '11/23', '12/25' ],
                 2001 => ['1/1', '1/15', '2/19', '5/28', '7/4', '9/3',  '11/22', '12/25' ],
                 2002 => ['1/1', '1/18', '2/18', '5/27', '7/4', '9/2',  '11/28', '12/25' ],
                 2003 => ['1/1', '1/17', '2/17', '5/26', '7/4', '9/1',  '11/27', '12/25' ],
                 2004 => ['1/1', '1/16', '2/16', '5/31', '7/5', '9/6',  '11/25', '12/25', '12/31' ],
                 2005 => ['1/1', '1/17', '2/21', '3/25', '5/30', '7/4', '9/5',  '11/24',  '12/25' ],
                 2006 => ['1/2', '1/16', '2/20', '4/14', '5/29', '7/4', '9/4',  '11/23', '12/25' ],
                 2007 => ['1/1', '1/15', '2/19', '4/6',  '5/28', '7/4', '9/3',  '11/22', '12/25' ],
                 2008 => ['1/1', '1/21', '2/18', '3/21', '5/26', '7/4', '9/1',  '11/27', '12/25' ],
                 2009 => ['1/1', '1/19', '2/16', '4/10', '5/25', '7/3', '9/7',  '11/26', '12/25' ],
                 2010 => ['1/1', '1/18', '2/15', '4/2',  '5/31', '7/5', '9/6',  '11/25', '12/25' ] }

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

  def trading_days(date_range)
    date_range.to_a.select do |date|
      wday = date.to_time.wday
      wday != 0 && wday != 6 && !holidays[date]
    end
  end

  def trading_days_from(date, number, dir=1)
    return date if number.zero?
    calendar_days = dir
    trading_days = []
    while trading_days.length < number
      next_date = date + calendar_days.days
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

  def trading_day_count(date1, date2)
    (date1..date2).to_a.count do |date|
      puts date
      wday = date.to_time.wday
      wday != 0 && wday != 6 && !holidays[date]
    end - 1
  end

  def format_dates_where_clause(dates)
    " IN ('#{dates.join("',' ")}' )"
  end

  def trading_to_calendar(start_date, day_count)
    trading_days_from(start_date, day_count).last
  end
end
