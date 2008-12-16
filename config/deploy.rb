desc "Set staging instance variables"
task :staging do
  set :application, "stock_db_capture"
  set :domain, "amd64"
  set :repository,  "ssh://kevin@amd64/home/git/stock_db_capture.git"
  set :branch, "master"
  set :user, "kevin"
  set :git_username, "kevin"
  set :use_sudo, false
  set :deploy_to, "/home/#{user}/apps/#{application}"
  set :deploy_via, :remote_cache
  set :chmod755, "app config db lib public vendor script/* public/disp*"
  set :mongrel_port, "80"

  role :app, domain
  role :web, domain
  role :db,  domain, :primary => true
end

desc "set the production instance variables"
task :production do
  set :application, "stock_db_capture"
  set :domain, "insgraph.com"
  set :repository,  "ssh://kevin@71.56.151.108/home/git/stock_db_capture.git"
  set :branch, "master"
  set :user, "insgrap"
  set :git_username, "kevin"
  set :use_sudo, false
  set :deploy_to, "/home/#{user}/apps/#{application}"
  set :deploy_via, :remote_cache
  set :chmod755, "app config db lib public vendor script/* public/disp*"
  set :mongrel_port, "4018"
  role :app, domain
  role :web, domain
  role :db,  domain, :primary => true
end

set :scm, :git

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
end


