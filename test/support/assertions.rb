module Assertions
  def assert_difference(callback, amount = 1)
    before = callback.call
    yield
    after = callback.call

    assert_equal before + amount, after, "Expected to have a difference by #{amount}"
  end
end

Minitest::Test.send(:include, Assertions)
