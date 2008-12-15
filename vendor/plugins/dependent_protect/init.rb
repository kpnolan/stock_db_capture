require 'dependent_protect'
ActiveRecord::Base.send :include, DependentProtect
