module Delayed
  module Extensions
    module Utility
      def payload_object_from_args(*args)
        klass = args.shift
        meth  = args.shift
        if defined?(ActionMailer::Base) && klass.class == Class && klass < ActionMailer::Base
          Delayed::PerformableMailer.new(klass, meth, args)
        else
          Delayed::PerformableMethod.new(klass, meth, args)
        end
      end

      def digest(payload, *args)
        if payload.args[0].send_if_respond_to(:key?, :job_id)
          payload = payload.dup
          payload.args = payload.args.dup
          payload.args[0] = payload.args[0].except(:job_id)
        end

        ([Digest::SHA1.hexdigest(payload.to_yaml)] + args).compact.join(':')
      end
    end
  end
end