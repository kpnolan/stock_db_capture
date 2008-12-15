require 'rubygems'
require 'active_record'
require 'test/unit'
require 'ostruct'
require File.join(File.dirname(__FILE__), '..', 'lib', 'dependent_protect')

class DependentProtectTest < Test::Unit::TestCase
  
  # Mocking everything necesary to test the plugin.
  class Company
    def initialize(with_or_without)
      @with_companies = with_or_without == :with_companies
    end
    
    def self.class_name
      self.name
    end
    
    def self.has_many(association_id, options = {}, &extension)
    end
    
    def self.create_reflection(macro, name, options, active_record)
      reflection = OpenStruct.new
      reflection.options = options.clone
      reflection.name = name
      return reflection
    end
    
    # not the real signature of the method, but forgive me
    def self.before_destroy(s)
      @@s = s
    end
    
    def destroy
      eval(@@s) if @@s
    end
    
    def companies
      cs = OpenStruct.new
      cs.with_companies = @with_companies
      def cs.find(arg)
        self.with_companies
      end
      return cs
    end
    
    include DependentProtect
    
    has_many :companies, :dependent => :protect
  end
  
  def test_destroy_protected_with_companies
    protected_firm = Company.new(:with_companies)
    assert_raises(ActiveRecord::ReferentialIntegrityProtectionError) { protected_firm.destroy }
  end
  
  def test_destroy_protected_without_companies
    protected_firm_without_companies = Company.new(:without_companies)
    assert_nothing_raised { protected_firm_without_companies.destroy }
  end
  
  def test_old_dependent_options
    assert_nothing_raised { Company.send(:has_many, :test1, { :dependent => :destroy }) }
    assert_nothing_raised { Company.send(:has_many, :test2, { :dependent => true }) }
    assert_nothing_raised { Company.send(:has_many, :test3, { :dependent => :delete_all }) }
    assert_nothing_raised { Company.send(:has_many, :test4, { :dependent => :nullify }) }
    assert_nothing_raised { Company.send(:has_many, :test5, { :dependent => nil }) }
    assert_nothing_raised { Company.send(:has_many, :test6, { :dependent => false }) }
    assert_nothing_raised { Company.send(:has_many, :test7) }
  end
  
  def test_bad_dependent_option
    assert_raises(ArgumentError) { Company.send(:has_many, :test8, { :dependent => :bad_option }) }
  end

end
