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
