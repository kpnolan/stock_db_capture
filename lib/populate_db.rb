require 'yahoofinance'

def add_tickers(eclass, tclass)
  xchg = nil
  FasterCSV.foreach("#{RAILS_ROOT}/config/symbols.csv") do |row|
    puts "Retrieving #{row[0]}"
    YahooFinance::get_quotes( YahooFinance::StandardQuote, row[0] ) do |qt|
      if qt.valid?
        unless xchg = eclass.find_by_symbol(row[1])
          puts "adding exchange #{row[1]}"
          xchg = eclass.create(:symbol => row[1])
        end
        puts "added stock #{row[0]}"
        tclass.create(:symbol => row[0], :exchange_id => xchg.id)
      else
        puts "          UKNOWN stock #{row[0]}"
      end
    end
  end
end


# TODO alias methods here
# TODO monkeypatch new .to_c method to String which returns a BigDecimal

def create_table_from_fields(table, type)
  hash = case type
           when 'x' : YahooFinance::STDHASH
           when 's' : YahooFinance::EXTENDEDHASH
           when 'r' : YahooFinance::REALTIMEHASH
         end
  hash.each_value do |v|
    coltype = map_column_type(v[0], v[1])
    columns = get_columns(v[1])
    columns.each do |name|
      table.send(coltype, name)
    end
  end
end

def map_column_type(name, method)

end
