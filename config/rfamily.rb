study(:rfamily, :increment => :redo) do
  desc "Study the relationships between the favorite 'r' indicators and nreturn and close"
  factor :rsi, :time_period => 14
  factor :rvi, :time_period => 14
  factor :rvig, :time_period => 14
  factor :identity, :slot => :close
end

populations do
#  $names = []
#  for year in 2000..2008
    name = "ibm_2008"
#    liquid = "min(volume) > 100000 and count(*) = #{trading_count_for_year(year)}"
    liquid = "ticker_id = 1674"
  year = 2008
    desc "Population of all stocks with a minimum valume of 100000 and have #{trading_count_for_year(year)} days traded in #{year}"
    scan name, :start_date => "01/01/#{year}", :end_date => "12/31/#{year}", :conditions => liquid
#    $names << name
#  end
end

experiment() do
  run :rfamily, :version => :memory, :with => :ibm_2008 do
    make_csv(:ibm)
  end
end
