module Analytics
  module Maker
    def make_analytics(options={}, &block)
      $analytics = builder = Analytics::Builder.new()
      builder.instance_eval(&block)
    end
  end
end
