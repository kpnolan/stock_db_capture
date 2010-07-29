require 'eventmachine'

class MyDeferrable
  include EM::Deferrable
  def go(str)
    puts "Deferrable: #{Thread.current}"
    puts "Go #{str} go"
  end
end
EM.run do
  s = EM.spawn do
    puts "Spawn: #{Thread.current}"
  end
  df = MyDeferrable.new
  df.callback do |x|
    df.go(x)
  end
  EM.add_timer(1) do
    puts "Timer: #{Thread.current}"
    df.set_deferred_status :succeeded, "SpeedRacer"
  end
  EM.add_timer(2) do
    25.times do |i|
      EM.defer do
        puts "Defer:#{i} #{Thread.current}"
        sleep(5)
      end
    end
  end
  EM.add_timer(3) do
    puts "3 sec timer"
  end

  EM.add_timer(10) do
    EM.stop
  end
end
