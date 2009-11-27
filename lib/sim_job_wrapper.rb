require 'sim/system_mgr'

class SimJobWrapper < Struct.new(:sim_job_id)
  def perform
    job = SimJob.find(sim_job_id)
    options = job.to_openstruct
    options.apply_defaults = false
    options.sim_job_id = sim_job_id
    job.update_attribute(:job_started_at, DateTime.now)
    Sim.run(options)
    job.update_attribute(:job_finished_at, DateTime.now)
  end
end
