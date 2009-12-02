require 'sim_job_wrapper'

class SimJobsController < ApplicationController
  def initialize_params
    master_config, local_config = {}, {}
    master_path = File.join(RAILS_ROOT, 'lib', 'sim', 'config.yml')
    user_path = File.join(ENV['USER'], '.satvatr', 'simulator.yml')
    master_config = YAML.load_file(master_path) if File.exists? master_path
    local_config = YAML.load_file(user_path) if File.exists? user_path
    default_options = master_config.merge(local_config)
    default_options.each_pair { |k,v| current_object[k] = v }
    current_object.user = ENV['USER']
  end

  make_resourceful do
    actions :all

    before :new do
      initialize_params()
    end

    after :create, :update do
      Delayed::Job.enqueue(SimJobWrapper.new(current_object.id))
    end
  end
end
