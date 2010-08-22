#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

class SmartFormBuilder < ActionView::Helpers::FormBuilder

  def label(field, html_options = {})
    super(field, html_options.has_key?(:label) ? html_options[:label] : field.to_s.titleize, html_options.reverse_merge(:class => self.options[:field_class]))
  end

  def text_field(field, html_options = {})
    label(field, html_options) +
      super(field, html_options.reverse_merge(:class => "#{self.options[:field_class]} #{html_options.delete(:class)}", :disabled => self.options[:readonly])) + brk(html_options)
  end

  def file_field(field, html_options = {})
    label(field, html_options) +
      super(field, html_options.reverse_merge(:class => self.options[:field_class], :disabled => self.options[:readonly])) + brk(html_options)
  end

  def date_select(field, options = {})
    label(field, options) +
      super(field, options.reverse_merge(:class => self.options[:field_class], :disabled => self.options[:readonly])) + brk(options)
  end

  def datetime_select(field, options = {})
    label(field, options) +
      super(field, options.reverse_merge(:class => self.options[:field_class], :disabled => self.options[:readonly])) + brk(options)
  end

  def text_area(field, options = {})
    label(field, options) +
      super(field, options.reverse_merge(:class => self.options[:field_class], :readonly => self.options[:readonly])) + brk(options)
  end

  def check_box(field, html_options = {})
    label(field, html_options) +
      super(field, html_options.reverse_merge(:class => self.options[:field_class], :disabled => self.options[:readonly])) + brk(html_options)
  end

  def password_field(field, html_options = {})
    label(field, html_options) +
      super(field, html_options.reverse_merge(:class => self.options[:field_class], :readonly => options[:readonly])) + brk(html_options)
  end

  def hidden_field(field, html_options = {})
    super(field, html_options.reverse_merge(:class => self.options[:field_class]))
  end

  def select(field, choices, options = {}, html_options = {})
    label_options = html_options.merge(:class => 'form-field')
    label_options.delete(:id)
    choices.unshift(['', nil]) if html_options[:include_blank]
    label(field, label_options)+
      super(field, choices, options, html_options.reverse_merge(:class => self.options[:field_class], :disabled => self.options[:readonly])) + brk(html_options)
  end

  def table_select(field_name, html_options = {}, &block)
    order = html_options.delete(:order)
    if html_options.has_key? :table
      tclass = html_options[:table].to_s.classify.constantize
    else
      tclass = field_name.to_s.gsub(/_id$/, '').camelize.constantize
    end
    if block_given?
      choices = tclass.send(:find, :all, :order => order ? order : :id).collect { |o| [block.call(o), o.id] }
    elsif html_options.has_key? :value
      choices = tclass.send(:find, :all, :order => order ? order : :id).collect { |o| [o.send(html_options[:value]), o.id] }
    else
      choices = tclass.send(:find, :all, :order => order ? order : :id).collect { |o| [o.name, o.id] }
    end
    select(field_name, choices, {}, html_options.reverse_merge(:class => self.options[:field_class]))
  end

  def submit(label, html_options = {})
    unless self.options[:readonly]
      super(label, html_options.reverse_merge(:class => self.options[:button_class])) + brk(html_options)
    end
  end

  private

  def brk(html_options)
    html_options[:nobreak].nil? ? "<br class='#{self.options[:field_class]}'/>" : ''
  end
end

def smart_form_for(object, options = { }, &proc)
  form_for(object, options.reverse_merge(:builder => SmartFormBuilder, :field_class => 'form-field', :button_class => 'form-button'), &proc)
end

def smart_mini_form_for(object, options = { }, &proc)
  form_for(object, options.reverse_merge(:builder => SmartFormBuilder, :field_class => 'mini-form-field', :button_class => 'mini-form-button'), &proc)
end

def smart_remote_form_for(object, options = { }, &proc)
  remote_form_for(object, options.reverse_merge(:builder => SmartFormBuilder, :field_class => 'form-field', :button_class => 'form-button'), &proc)
end

def smart_fields_for(object, options = {}, &proc)
  fields_for(object, options.reverse_merge(:builder => SmartFormBuilder, :field_class => 'form-field', :button_class => 'form-button'), &proc)
end

def table_lookup(klass, id, attr = :name, msg = 'Nil')
  return '' if id.nil?
  field = "#{klass.to_s.downcase}_id}"
  (obj = klass.find(id)).nil? ? msg : obj.send(attr)
end
