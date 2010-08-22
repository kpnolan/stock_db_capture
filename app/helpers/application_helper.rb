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
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def table_lookup(klass, id, attr = :name, msg = 'Nil')
    return '' if id.nil?
    field = "#{klass.to_s.downcase}_id}"
    (obj = klass.find(id)).nil? ? msg : obj.send(attr)
  end

  # lkup
  def lkup(assoc, attr = :name, msg = '<center>-</center>')
    (assoc && (str = assoc.send(attr))) ? str : msg
  end

  def cond_prepend(str, char)
  !str.blank? ? char + str : str
  end

  def format_phone(number)
    number.to_s.gsub(/^(\d{3})(\d{3})(\d{4})$/, '\1-\2-\3')
  end

  #format into City, ST, 97219-1040
  def format_csz(contact)
    "#{contact.city}, #{State.find(contact.state).abbrev}, #{contact.zip5.to_s}#{cond_prepend(contact.zip4.to_s, '-')}"
  end
end
