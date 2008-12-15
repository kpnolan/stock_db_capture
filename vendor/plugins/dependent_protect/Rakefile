require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the dependent_protect plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the dependent_protect plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'DependentProtect'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Prepares a new release for the dependent_protect plugin.'
task :release => [:create_tag, :upload_docs]

task :create_tag do
  unless ENV.include?('VERSION')
    version = Time.now.strftime('%Y%m%d')
  else
    version = ENV['VERSION']
  end
  
  repo_root = 'http://svn.ruido-blanco.net/dependent_protect'
  tag_name = "dependent_protect-#{version}"
  branch_name = "rel#{version}"
  
  puts "creating new branch #{branch_name}"
  `svn copy #{repo_root}/trunk #{repo_root}/branches/#{branch_name} -m 'branching #{branch_name}'`
  
  puts "creating new tag #{tag_name} from branch #{branch_name}"
  `svn copy #{repo_root}/branches/#{branch_name} #{repo_root}/tags/#{tag_name} -m 'tagging #{tag_name}'`
end

task :upload_docs => :rdoc do
  puts 'Deleting previous rdocs'
  `ssh ruido-blanco.net 'rm -Rf /home/drodriguez/ruido-blanco.net/dependent-protect-doc/*'`
  
  puts "Uploading new rdocs"
  `scp -r rdoc/* ruido-blanco.net:/home/drodriguez/ruido-blanco.net/dependent-protect-doc`
end
