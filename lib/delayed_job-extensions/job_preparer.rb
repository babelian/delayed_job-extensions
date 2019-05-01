require 'delayed/backend/job_preparer'

module Delayed
  module Backend
    class JobPreparer
      prepend(Module.new do
        # Add additional options
        #   :once        - alias for :unique
        #   :run_in      - converts 5.minutes to { run_at: 5.minutes.from_now, unique: true }
        #   :run_once_in - converts 5.minutes to { run_at: 5.minutes.from_now, unique: true }
        #   :run_once_at - converts time to { run_at: time, unique: true }
        #   :run_only_at - like :run_once_at, but unique by time (can be multiple times)
        #   :unique      - {Delayed::Job#enqueue} will ensure this is only run once per :unique_key
        #   :unique_key  - [String, Array<String>] to append to the default unique_key
        def prepare

          if options.delete(:once)
            options[:unique] = true
          end

          if time = options.delete(:run_once_at)
            options[:run_at] = time
            options[:unique] = true
          end

          if secs = options.delete(:run_in)
            options[:run_at] ||= Time.now.utc + secs
          end

          if secs = options.delete(:run_once_in)
            options[:run_at] ||= Time.now.utc + secs
            options[:unique] = true
          end

          if only_at = options.delete(:run_only_at)
            options[:run_at] = only_at
            options[:unique] = true
            options[:unique_key] = only_at.to_i
          end

          super
        end
      end)
    end
  end
end
