require 'monitor'

module Task

  JobTracker = Struct.new(:id, :name, :sent_at, :received_at, :eval_started_at, :eval_completed_at, :completed_at, :last_thread, :message) do
    def initialize(message, pop=false)
      self.id = message.id
      self.name = message.name
      self.message = message
      self.sent_at = Time.now
      populate(message) if pop
    end

    def populate(msg)
      members.each { |meth| send("#{meth}=".to_sym, msg.send(meth)) if msg.respond_to? meth }
    end

    def fmt(meth)
      val = send meth
      val ? val.strftime('%H:%M:%S') : :empty
    end
  end

  TrackerContainer = Struct.new(:hash) do
    def initialize()
      self.hash = { }
      self.hash.extend(MonitorMixin)
    end

    def use(jt)
      self.hash[jt.id] = jt
    end

    def sent(msg)
      self.hash[msg.id] = JobTracker.new(msg)
    end

    def received(id)
      self.hash[id] ||= JobTracker.new()
      self.hash[id].received_at = Time.now
    end

    def eval_start(id)
      self.hash[id].eval_started_at = Time.now
    end

    def eval_complete(id)
      self.hash[id].eval_completed_at = Time.now
    end

    def eval_thread(id, thread_name)
      self.hash[id].last_thread = thread_name
    end

    def completed(id)
      self.hash[id] ||= JobTracker.new()
      self.hash[id].completed_at = Time.now
      self.hash[id].message = nil               # Free up some memory
    end

    def synch_and_send(meth)
      self.hash.synchronize {
        send meth
      }
    end

    def average_defer_times()
      sample_count = {}
      avg_defer_times = {}
      by_name = hash.values.group_by { |jt| jt.name }
      by_name.each_pair do |k,v|
        avg_defer_times[k] = v.inject(0.0) do |sum, jt|
          if jt.eval_completed_at.nil?
            sum
          else
            sample_count[k] ||= 0
            sample_count[k] += 1
            delta = jt.eval_completed_at - jt.eval_started_at
            sum += delta
          end
        end
      end
      avg_defer_times.each_pair { |k,v| avg_defer_times[k] = v/sample_count[k] if sample_count[k] }
      # means = avg_defer_times
      # by_name.each_pair do |k,v|
      #   var_defer_times[k] = v.inject(0.0) do |var, jt|
      #     if jt.eval_completed_at.nil?
      #       var
      #     else
      #       delta = jt.eval_completed_at - jt.eval_started_at
      #       diff = delta - means[k]
      #       var += diff*diff
      #     end
      #   end
      # end
      # stddev = var_defer_times.map { |pair| [pair.fist, pair.second/(sample_cound[pair.first]-1)] }
      avg_defer_times
    end

    def incomplete_jobs(lock=false)
      sync_and_send :incomplete_jobs if lock
      self.hash.values.select { |jt| jt.completed_at.nil? }
    end
  end
end

if __FILE__ == $0
  require 'ostruct'
  names = Array.new(6) { |i| "task#{i}".to_sym }
  tc = Task::TrackerContainer.new
  100.times do |i|
    msg = OpenStruct.new(:id => i, :name => names[i%6].to_sym, :eval_started_at => Time.now, :eval_completed_at => Time.now + rand(10))
    jt = Task::JobTracker.new(msg, true)
    tc.use(jt)

  end
  adts = tc.average_defer_times
  puts adts.inspect
end
