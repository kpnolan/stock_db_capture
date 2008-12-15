= dependent => :protect option

Adds a new option :protect for the parameter <tt>:depends</tt> from +has_many+
method. This option forbids destroying records with associated records in a
association created with <tt>:dependent => :protect</tt> option, more or less
like <tt>ON DELETE RESTRICT</tt> SQL statement. If you try to destroy a record with
associated records it will raise a
ActiveRecord::ReferentialIntegrityProtectionError (defined also in this 
plugin).

Based on the idea and the code from diego.algorta@gmail.com in Ruby on Rails
ticket #3837 (http://dev.rubyonrails.org/ticket/3837).

You can download this plugin at:

http://svn.ruido-blanco.net/dependent_protect/trunk

== Author

Daniel Rodríguez Troitiño <drodrigueztroitino@yahoo.es>, based on the ideas and
the code from <diego.algorta@gmail.com>.
