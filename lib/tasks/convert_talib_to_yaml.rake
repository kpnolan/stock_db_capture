# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

namespace :active_trader do
  desc "convert talib xml to yaml"
  task :convert_talib_to_yaml do
    `xyx "#{File.join("#{RAILS_ROOT}",'lib', 'talib', 'ext', 'ta_func_api.xml')}" > "#{RAILS_ROOT}/config/ta_func_api.yml"`
  end
end
