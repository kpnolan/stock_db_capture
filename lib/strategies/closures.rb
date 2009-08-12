module Strategies
  module Closures

    def define_current_closure(name, params)
      conditions = {
        :macdfix => { :threshold => 0 },
        :rsi => { :threshold => 50 },
        :rvi => { :threshold => 50 }
      }
      conditions.each_pair do |k,v|
        conditions[k] = v.merge!(params)
      end
      condidtions
    end
  end
end
