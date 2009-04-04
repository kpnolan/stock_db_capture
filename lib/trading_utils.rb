module TradingUtils

    HOLIDAYS = [ '1/1/2009', '1/19/2009', '2/16/2009', '5/25/2009', '7/3/2009', '9/7/2009',
               '10/12/2009', '11/11/2009', '11/26/2009', '12/25/2009' ].map { |str| Date.parse(str) }

  def trading_days(date_range)
    (date_range.to_a - HOLIDAYS).select { |date| (1..5).include?(date.to_time.wday) }
  end

  def trading_days_from(date, number)
    calendar_days = 0
    trading_days = []
    while trading_days.length < number
      next_date = date + calendar_days
      if [0,6].include?(next_date.to_time.wday)
        calendar_days += 1
      elsif HOLIDAYS.include? next_date
        calendar_days += 1
      else
        trading_days << next_date
        calendar_days += 1
      end
    end
    return trading_days, calendar_days
  end

  def trading_day_count(date1, date2)
    trading_days(date1..date2).length
  end

  def format_dates_where_clause(dates)
    " IN ('#{dates.join("',' ")}' )"
  end

  def trading_to_calender(start_date, trading_day_count)
    dummy, count = trading_date_from(start_date, trading_day_count)
    start_date + count.days
  end
end
