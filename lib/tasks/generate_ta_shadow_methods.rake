require 'rubygems'
require 'xmlsimple'
require 'build_shadow'

namespace :active_trader do
  desc "generate show methods for ta-lib"
  task :generate_ta_shadow_methods do
    File.open("#{RAILS_ROOT}/lib/technical_analysis.rb", "w") do |f|
      shadow = BuildShadow.new(f)
      shadow.emit_header
      config = XmlSimple.xml_in("#{RAILS_ROOT}/lib/talib/ext/ta_func_api.xml")
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
