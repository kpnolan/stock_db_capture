require 'set'

module LoadEtf
  def load_etf()
    IO.foreach("#{RAILS_ROOT}/tmp/etfs.csv") do |str|
      begin
        str.chomp!
        Ticker.create!(:symbol => str, :exchange_id => 26, :dormant => false, :active => true)
        puts "created #{str}"
      rescue Exception => e
        puts "#{e.message} with #{str}"
      end
    end
  end
end
