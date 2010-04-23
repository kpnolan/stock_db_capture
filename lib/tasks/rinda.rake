require 'rinda/rinda'

namespace :rinda do
  desc "Start the Rinda RingServer"
  task :ring do
    `ringserver`
  end

  desc "Start Rinda Tuplespace"
  task :tuplespace => :ring do
    `tuplespace`
  end
end

