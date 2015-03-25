module Rubby
  # Why use three lines to define a method when you can use one?
  def defn(name, block)
    name.tap { |n| define_method name, block }
  end
end
