# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'xmlsimple'

class BuildShadow

  INTERNAL_ARGS = %w{ High Low Close Volume Open Close }

  attr_accessor :internal_args, :name, :out_buff, :input_args, :graph_hint, :file

  def initialize(file)
    self.file = file
    self.internal_args = []
    self.input_args = []
    self.out_buff = ''
    self.graph_hint = nil
  end

  def emit_header
    buffer <<-DONE
module TechnicalAnalysis
    UNSTABLE_PERIOD_METHODS = [ :adx, :adxr, :atr, :cmo, :dx, :ema, :ht_dcperiod, :ht_dcphace, :ht_phasor, :ht_sine,
                             :ht_trendline, :ht_trendmode, :kama, :mama, :mfi, :minus_di, :minus_dm, :natr, :plus_di, :plus_dm,
                             :rsi, :stoch_rsi, :t3, :all ]

  def self.included(base)
    base.extend(ClassMethods)
    base.talib_init()
  end

  require 'ta_class_methods'

DONE

  end

  def emit_preamble
    buffer <<-DONE
# Copyright Kevin P. Nolan 2009-2010 All Rights Reserved.

###############################################################################################################
# DON'T EDIT THIS FILE !!!
# This file was automatically generated from 'ta_func.xml'
# If, for some reason the interface to Talib changes, but the Swig I/F file 'ta_func.swg' must change as well
# as 'ta_func.xml'. This file contains the "shadow methods" that the writers of the SWIG I/F deemed unneccessary.
# I think the Swig interface is still to low-level and created this higher-level interface that really is designed
# to be a mixin to the Timeseries class upon with talib functions operate.
################################################################################################################
DONE
  end

  def emit_trailer
    file.puts "end\n"
  end

  def meta_info(top_hash)
    self.graph_hint = (flags = top_hash["Flags"]) && flags.first["Flag"].first.gsub(/[ ]/, '_').downcase.to_sym
  end

  def emit_method(name, desc, iargs, oargs, opt_args)
    self.name = name.first.downcase
    emit_decl(name.first.downcase, desc.first)
    emit_input_args(iargs)
    emit_decl_close
    emit_default_options(opt_args)
    emit_prelude(opt_args)
    emit_invoke_primative
    emit_input_args()
    emit_internal_args
    emit_opt_args(opt_args)
    emit_primative_close
    emit_post_processing
    buffer "  end\n\n"
    file.puts out_buff
  end

  def emit_decl(name, desc)
    buffer "  ##{desc}\n"
    buffer "  def #{name}( "
  end

  def emit_decl_close
    cond_comma
    buffer "options={})\n"
  end

  def emit_prelude(opt_args)
    options = expand_opt_args(opt_args)
#    options = (',' << options) unless options.empty?
    buffer "    idx_range = calc_indexes(:ta_#{format_name(name)}_lookback#{options})\n"
  end

  def format_name(name)
    name.gsub(/cdl([0-9])/, 'cdl_\1')
  end

  def emit_invoke_primative
    buffer "    result = Talib.ta_#{format_name(name)}(idx_range.begin, idx_range.end, "
  end

  def emit_post_processing
    if graph_hint
      buffer "    memoize_result(self, :#{name}, idx_range, options, result, :#{graph_hint})\n"
    else
      buffer "    memoize_result(self, :#{name}, idx_range, options, result)\n"
    end
  end

  def emit_primative_close
    buffer ")\n"
  end

  def emit_input_args(iargs=nil)
    if iargs.nil?
      buffer input_args.map { |arg| "#{arg}" }.join(', ')
    else
      ret = iargs.map do |arg|
        name = arg["Name"].first
        if name =~ /^in.+[0-9]*/
          self.input_args << name
          "#{name}"
        elsif INTERNAL_ARGS.include? name
          self.internal_args << name
          nil
        else
          raise ArgumentError, "Don't know what to do with #{self.name}: #{name}"
        end
      end
    end
    buffer ret.compact.join(', ') if ret
  end

  def clear
    self.internal_args = []
    self.input_args = []
    self.out_buff = ''
  end

  def emit_internal_args
    buffer internal_args.map(&:downcase).join(', ')
  end

  def cond_comma
    self.out_buff << ', ' if self.out_buff.last != ' '
  end

  def emit_default_options(opt_args)
    return if opt_args.empty?
    buffer "    options.reverse_merge!("
    str = opt_args.map do |arg|
      name = arg["Name"].first.gsub(/[ ]/, '_').downcase
      type = arg["Type"] && arg["Type"].first
      default = arg["DefaultValue"] &&  arg["DefaultValue"].first
      default = case type
                when "Integer" then default.to_i
                when "Double" then default.to_f
                else
                  default.to_i
                end
      ":#{name} => #{default}"
    end.join(', ')
    buffer str
    buffer ")\n"
  end

  def emit_opt_args(opt_args)
    buffer expand_opt_args(opt_args)
  end

  def expand_opt_args(opt_args)
    if opt_args.empty?
      ret = nil
    else
      ret =  opt_args.map do |arg|
        name = arg["Name"].first.gsub(/[ ]/, '_').downcase
        "options[:#{name}]"
      end.join(', ')
    end
    ret.nil? ? '' : ', '+ret
  end

  def buffer(str)
    self.out_buff << str
  end

  class << self
    def generate_shadow_file(basename)
      File.open(File.join(RAILS_ROOT, 'lib', basename), "w") do |f|
        shadow = BuildShadow.new(f)
        shadow.emit_preamble
        shadow.emit_header
        config = XmlSimple.xml_in(File.join(RAILS_ROOT, 'lib', 'talib', 'ext', 'ta_func_api.xml'))
        config['FinancialFunction'].each do |h|
          name = h['Abbreviation']
          desc = h['ShortDescription']
          iargs = h['RequiredInputArguments'].first['RequiredInputArgument']
          oargs = h['OutputArguments'].first['OutputArgument']
          optargs = h['OptionalInputArguments'].first['OptionalInputArgument'] if  h['OptionalInputArguments']
          optargs = [] unless  h['OptionalInputArguments']
          shadow.meta_info(h)
          shadow.emit_method(name, desc, iargs, oargs, optargs)
          shadow.clear
        end
        shadow.emit_trailer
      end
    end
  end
end
