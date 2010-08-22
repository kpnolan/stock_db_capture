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
module DbMaintenance
  def purge_db(logger)
    table_ary = DailyBar.connection.select_values("show tables")
    filenames = Dir.new(File.join(RAILS_ROOT, 'app', 'models')).entries.delete_if {  |d| d == '.' || d == '..' }
    tables = filenames.map { |str| str.gsub(/[.]rb$/,'') }.map(&:tableize)
    tables.concat ['delayed_jobs', 'schema_migrations', 'sessions', 'watch_list']
    drop_tables = table_ary - tables
    drop_tables.each do |table|
      DailyBar.connection.execute("drop table #{table}")
    end
  end

  def output_tables()
    path = File.join(RAILS_ROOT, 'tmp', 'table_dumps')
    table_ary = DailyBar.connection.select_values("show tables")
    table_ary.each do |table|
      puts "mysqldump -ukevin -pTroika3. active_trader_production #{table} | bzip2 > #{path}/#{table}.sql.bz2"
      `mysqldump -ukevin -pTroika3. active_trader_production #{table} | bzip2 > #{path}/#{table}.sql.bz2`
    end
  end
end
