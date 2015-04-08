module Rubby
  THROTTLING = {active: true}

  # Why use three lines to define a method when you can use one?
  def defn(name, block)
    name.tap { |n| define_method name, block }
  end

  def self.current_time
    Time.now
  end

  def throttle duration, method_name
    last_call = nil

    method_name.tap do |name|
      body = instance_method name
      define_method name do |*args, &block|
        if !Rubby::THROTTLING[:active] || last_call.nil? || ((last_call + duration) <=  Rubby.current_time)
          last_call = Rubby.current_time
          body.bind(self).call(*args, &block)
        end
      end
    end
  end
end
