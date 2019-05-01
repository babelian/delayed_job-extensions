require 'delayed_job_active_record'
require 'delayed_job-extensions/utility'

module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        extend Delayed::Extensions::Utility

        attr_accessible :priority, :run_at, :queue, :payload_object,
                        :failed_at, :locked_at, :locked_by, :handler,
                        :unique_key

        #
        # Named Scopes
        #

        scope :by_performable, proc { |*args|
          where('unique_key LIKE ?', digest(payload_object_from_args(*args)) + '%')
        }

        scope :active, -> { where(failed_at: nil) }
        scope :backlog, -> { where(failed_at: nil, locked_at: nil).where('run_at < ?', Time.now) }
        scope :failed, -> { where.not(failed_at: nil) }
        scope :locked, -> { where.not(locked_at: nil) }
        scope :multiple_attempts, -> { active.where('attempts > 0') }

        scope :run_only_at, -> { where(%q(LOCATE(':', unique_key) = 41)) }
        scope :not_unique_by_run_at, -> { where(%q(LOCATE(':', unique_key) != 41)) }

        #
        # Class methods
        #

        class << self
          def enqueue(*args)
            options = Delayed::Backend::JobPreparer.new(*args).prepare

            # HACK

            if column_names.include?('unique_key')
              options[:unique_key] = digest(options[:payload_object], *options[:unique_key])
            end

            return where(unique_key: options[:unique_key]) if options[:find]

            if options.delete(:unique)
              scope = where(unique_key: options[:unique_key])
              scope = scope.where(locked_at: nil) if options.delete(:unique_unless_locked)

              if job = scope.first
                job.update(options) unless job.locked_at
                return job
              end
            end

            # END HACK

            enqueue_job(options)
          end
        end
      end

      #
      # Instance Methods
      #

    end
  end
end
