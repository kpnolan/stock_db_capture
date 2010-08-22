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
