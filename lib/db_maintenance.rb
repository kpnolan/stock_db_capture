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
