require_relative './test_helper.rb'

require_relative '../rubby_module.rb'

class RubbyModuleTest < Minitest::Unit::TestCase
  extend Rubby

  def test_defn
    assert !respond_to?(:new_method)

    called = false
    self.class.defn :new_method, -> { called = true }
    assert respond_to?(:new_method)

    new_method

    assert called
  end

  class Throttled
    extend Rubby

    def initialize(counter)
      @counter = counter
    end

    throttle 5, def x
      @counter[:x] += 1
    end

    throttle 10, def y
      @counter[:y] += 1
    end
  end

  def test_throttle
    invocations = { x: 0, y: 0}

    def Rubby.current_time
      0
    end

    throttled = Throttled.new(invocations)

    # Both methods can be called the first time
    throttled.x
    throttled.y
    assert_equal 1, invocations[:x]
    assert_equal 1, invocations[:y]

    # A second time with no time passing has no effect
    throttled.x
    throttled.y
    assert_equal 1, invocations[:x]
    assert_equal 1, invocations[:y]

    # A second time with insufficient time passing has no effect
    def Rubby.current_time
      1
    end
    throttled.x
    throttled.y
    assert_equal 1, invocations[:x]
    assert_equal 1, invocations[:y]

    # Time passing until the x threshold allows only x to execute
    def Rubby.current_time
      5
    end
    throttled.x
    throttled.y
    assert_equal 2, invocations[:x]
    assert_equal 1, invocations[:y]

    # Since y = 2x, allowing the y threshold will allow both to execute again.
    def Rubby.current_time
      10
    end
    throttled.x
    throttled.y
    assert_equal 3, invocations[:x]
    assert_equal 2, invocations[:y]

    # Again, a further invocation as no effect
    throttled.x
    throttled.y
    assert_equal 3, invocations[:x]
    assert_equal 2, invocations[:y]
  end

end
