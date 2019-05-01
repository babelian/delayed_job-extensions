module Delayed
  module Matchers
    class HaveDelayedJob
      def initialize(expected, *args)
        @expected = expected
        @args = args
      end

      attr_reader :run_at, :args

      def with(*args)
        @args = args
        self
      end

      def running_at(run_at = nil)
        @run_at = run_at
        self
      end

      def matches?(target)
        scope(target).any?
      end

      def failure_message
        s  = "expected delayed job #{@expected.inspect}"
        s += "(#{args.join(', ')})" unless args.empty?
        s
      end

      def failure_message_when_negated
        s = "did not expect delayed job #{@expected.inspect}"
        s += "(#{args.join(', ')})" unless args.empty?
        s
      end
      alias negative_failure_message failure_message_when_negated

      def scope(target)
        scope = Delayed::Job.performable(target, @expected, *args)
        scope = scope.where(run_at: run_at) if run_at
        scope
      end
    end

    def have_delayed_job(expected, *args) # rubocop:disable Naming/PredicateName
      HaveDelayedJob.new(expected, *args)
    end
  end
end