def format_et(seconds)
  if seconds > 60.0 and seconds < 120.0
    format('%d minute and %d seconds', (seconds/60).floor, seconds.to_i % 60)
  elsif seconds > 120.0
    format('%d minutes and %d seconds', (seconds/60).floor, seconds.to_i % 60)
  else
    format('%2.2f seconds', seconds)
  end
end


startt = Time.now
1000.times { Thread.new { sleep 20} }
endt = Time.now

puts format_et(endt - startt)



