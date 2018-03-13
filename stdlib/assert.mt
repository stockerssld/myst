defmodule Assert
  # AssertionFailure
  #
  # An AssertionFailure is a container object that is raised when an assertion
  # fails to complete.
  deftype AssertionFailure
    def initialize(@left, @right, @message : String); end
    def initialize(@left, @right)
      @message = ""
    end

    def left; @left; end
    def right; @right; end

    def to_s
      "Assertion failed: `<(@message)>`\n" +
      "     left: <(@left)>\n" +
      "    right: <(@right)>\n"
    end
  end


  # Assertion
  #
  # An object representing a pending assertion for a static value.
  # Instantiating an `Assertion` object only stores the "left-hand" value.
  # Making actual assertions is done with the instance methods on the object.
  # For example, equality can be asserted with `%Assertion{true}.equals(true)`.
  #
  # When an assertion succeeds, the method will return normally, but if the
  # assertion fails, the method will raise an `AssertionFailure` object with
  # information about the failure.
  deftype Assertion
    def initialize(@value); end

    # truthy -> self
    #
    # Asserts that the value is truthy (not `false` or `nil`).
    def is_truthy
      @value || raise %AssertionFailure{@value, true, "truthy"}
      self
    end

    # falsey -> self
    #
    # Asserts that the value is falsey (either `false` or `nil`).
    def is_falsey
      @value && raise %AssertionFailure{@value, false, "falsey"}
      self
    end

    # is_true -> self
    #
    # Asserts that the value is exactly the boolean value `true`.
    def is_true
      @value == true || raise %AssertionFailure{@value, true, "exactly true"}
      self
    end

    # is_false -> self
    #
    # Asserts that the value is exactly the boolean value `false`.
    def is_false
      @value == false || raise %AssertionFailure{@value, false, "exactly false"}
      self
    end

    # is_nil -> self
    #
    # Asserts that the value is `nil` (false is not allowed).
    def is_nil
      @value == nil || raise %AssertionFailure{@value, nil, "nil"}
      self
    end

    # is_not_nil -> self
    #
    # Asserts that the value is not `nil` (false is allowed).
    def is_not_nil
      @value != nil || raise %AssertionFailure{@value, nil, "not nil"}
      self
    end


    # equals(other) -> self
    #
    # Assert that the value is equal to `other` using its `==` method.
    def equals(other)
      unless @value == other
        raise %AssertionFailure{@value, other, "left == right"}
      end

      self
    end

    # does_not_equal(other) -> self
    #
    # Assert that the value is not equal to `other` using its `!=` method.
    def does_not_equal(other)
      unless @value != other
        raise %AssertionFailure{@value, other, "left != right"}
      end

      self
    end

    # less_than(other) -> self
    #
    # Assert that the value is less than `other` using its `<` method.
    def less_than(other)
      unless @value < other
        raise %AssertionFailure{@value, other, "left < right"}
      end

      self
    end

    # less_or_equal(other) -> self
    #
    # Assert that the value is less than or equal to `other` using its `<=`
    # method.
    def less_or_equal(other)
      unless @value <= other
        raise %AssertionFailure{@value, other, "left <= right"}
      end

      self
    end

    # greater_or_equal(other) -> self
    #
    # Assert that the value is greater than or equal to `other` using its `>=`
    # method.
    def greater_or_equal(other)
      unless @value >= other
        raise %AssertionFailure{@value, other, "left >= right"}
      end

      self
    end

    # greater_than(other) -> self
    #
    # Assert that the value is greater than `other` using its `>` method.
    def greater_than(other)
      unless @value > other
        raise %AssertionFailure{@value, other, "left > right"}
      end

      self
    end

    # between(lower, upper) -> self
    #
    # Assert that the value is between `lower` and `upper` (inclusively), using
    # only the `<=`operator on the value for comparisons.
    def between(lower, upper)
      unless lower <= @value && @value <= upper
        raise %AssertionFailure{@value, [lower, upper], "lower <= value <= upper"}
      end

      self
    end

    # <(other) -> self
    #
    # Operator alias for `less_than(other)`.
    def <(other)
      less_than(other)
    end

    # <=(other) -> self
    #
    # Operator alias for `less_or_equal(other)`.
    def <=(other)
      less_or_equal(other)
    end

    # ==(other) -> self
    #
    # Operator alias for `equals(other)`.
    def ==(other)
      equals(other)
    end

    # <=(other) -> self
    #
    # Operator alias for `does_not_equal(other)`.
    def !=(other)
      does_not_equal(other)
    end


    # >=(other) -> self
    #
    # Operator alias for `greater_or_equal(other)`.
    def >=(other)
      greater_or_equal(other)
    end

    # >(other) -> self
    #
    # Operator alias for `greater_than(other)`.
    def >(other)
      greater_than(other)
    end
  end


  # BlockAssertion
  #
  # An object representing a pending assertion for a block of code. Similar to
  # the regular `Assertion`, instantiating a `BlockAssertion` only stores the
  # block of code to be run when making the assertion. Making the actual
  # assertion is done by calling methods on the resulting object.
  #
  # `BlockAssertion` is most useful for asserting that running a code block has
  # a specific side effect, namely raising errors.
  deftype BlockAssertion
    def initialize(@block)
      @arguments_for_call = []
    end

    # raises -> self
    # raises(value) -> self
    #
    # Assert that calling the block raises an error with the given value. If no
    # value is given, the assertion just checks that an error is raised.
    #
    # The block will be called with whatever arguments have been set with
    # `called_with_arguments`. By default, no arguments will be given.
    def raises(expected_error)
      @block(*@arguments_for_call)
      raise %AssertionFailure{"block(<(@arguments_for_call.join(", "))>)", expected_error, "expected the block to raise an error"}
    rescue <expected_error>
      # If this rescue matches, the block must have raised a matching error,
      # so the assertion is successful.
      self
    rescue ex : AssertionFailure
      raise ex
    rescue actual_error
      # If any other error is raised, the assertion has not passed. This block
      # provides a more helpful message containing the actual and expected errors.
      raise %AssertionFailure{expected_error, actual_error, "error from block did not match expected"}
    end

    def raises
      block(*@arguments_for_call)
      raise %AssertionFailure{"block(<(@arguments_for_call.join(", "))>)", "any error", "expected the block to raise an error"}
    rescue ex : AssertionFailure
      # If the assertion failure is what's being raised, pass it through.
      raise ex
    rescue
      # Otherwise, if this rescue matches, the block must have raised a
      # matching error, so the assertion is successful.
      self
    end


    # succeeds -> self
    #
    # Assert that calling the block completes successfully (does not raise an
    # error).
    def succeeds
      @block(*@arguments_for_call)
      self
    rescue err
      raise %AssertionFailure{"block(<(@arguments_for_call.join(", "))>)", err, "expected no error from block"}
    end

    # returns -> self
    #
    # Assert that calling the block returns the given value.
    def returns(expected_result)
      unless @block(*@arguments_for_call) == expected_result
        raise %AssertionFailure{"block(<(@arguments_for_call.join(", "))>)", expected_result, "return value from block did not match expected value"}
      end

      self
    rescue err
      raise %AssertionFailure{"block(<(@arguments_for_call.join(", "))>)", err, "expected no error from block"}
    end


    # called_with_arguments(*args) -> self
    #
    # Set the arguments to be used when calling the block for an assertion.
    def called_with_arguments(*args)
      @arguments_for_call = args
      self
    end
  end
end



# The global entrypoint to writing assertions.
def assert(value)
  %Assert.Assertion{value}
end

# The global entrypoint for writing assertions with code blocks.
#
# Example:
#   assert{ raise :woops }.raises(:woops)
def assert(&block)
  %Assert.BlockAssertion{block}
end