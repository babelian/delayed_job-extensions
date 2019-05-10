require 'rufus/scheduler'

class Rufus::Scheduler::Job
  def kind
    self.class.name.split('::').last.underscore.sub(/_job$/, '')
  end

  def kind_trigger
    [kind, original]
  end
end

lockfile = Rails.root.join('tmp', 'pids', 'scheduler.pid').to_s
scheduler = Rufus::Scheduler.new(lockfile: lockfile)

def scheduler.add(event_name, kind, trigger, options = {}, &block)
  send(kind, trigger, options) do
    PledgeCore.event(event_name, kind: kind, trigger: trigger, jobs: options[:jobs]) do
      ActiveRecord::Base.connection_pool.with_connection do
        begin
          block.call
        rescue => e
          SiteMailer.error(e, event_name: event_name, kind: kind, options: options).deliver
        end
      end
    end
  end
end

def scheduler.handle_exception(job, error)
  SiteMailer.error(error, job.inspect + ' ' + job.params.inspect).deliver
end

# Do not use scheduler.every as it is not as reliable as scheduler.cron when it comes to restarts.
# sleep offsets are used to avoid ActiveRecord::ConnectionTimeoutError on threading

# If Scheduler is running
if scheduler.up?
  $PROGRAM_NAME += ' (scheduler)'

  # Queue all ScheduledJobs
  ScheduledJob.grouped_by_kind_trigger.each do |kind_trigger, jobs|
    kind, trigger = kind_trigger
    scheduler.add("scheduler.#{kind}.#{trigger}", kind, trigger, jobs: jobs.map(&:full_name)) do
      jobs.each(&:queue_job)
    end
  end

  # Output the current schedule
  data = scheduler.jobs.sort_by(&:kind_trigger).map do |job|
    { kind: job.kind, trigger: job.original }.merge(job.opts)
  end

  PledgeCore.event('scheduler.started', data: data.to_yaml)
end
