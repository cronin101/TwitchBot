module Rubby
  THROTTLING = {active: true}

  def self.current_time
    Time.now
  end

  def throttle duration, method_name
    last_call = nil

    method_name.tap do |name|
      body = instance_method name
      define_method name do |*args, &block|
        if Rubby.can_execute last_call, duration
          last_call = Rubby.current_time
          body.bind(self).call(*args, &block)
        end
      end
    end
  end

  def self.can_execute(last_call, interval)
    !Rubby::THROTTLING[:active] || last_call.nil? || (last_call + interval <=  Rubby.current_time)
  end
end
