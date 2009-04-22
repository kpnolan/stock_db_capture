module Analytics
  module Maker
    def analytics(options={}, &block)
      $analytics = = Analytics::Builder.new()
      builder.instance_eval(&block)
    end
    def populations(options={}, &block)
      $populations Popu
    end
  end
end
