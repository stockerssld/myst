module Myst
  class Interpreter
    # Resolve the TType object representing the type of `value`. For primitive
    # types, these are _always_ looked up in the Kernel. For Instances, the
    # type is looked up from the type reference on the instance itself. For
    # Types and Modules, the value itself is returned.
    def __typeof(value : Value)
      case value
      when ContainerType
        value
      when TInstance
        value.type
      when Value
        @kernel.scope[value.type_name].as(TType)
      else
        raise "Can't resolve type of #{value}"
      end
    end

    # Resolve the Scope for `value`. For primitives, this returns the instance
    # scope of the Type for that value. For Instances, Types, and Modules, this
    # just returns `.scope` for that value.
    def __scopeof(value : Value) : Scope
      case value
      when TInstance
        value.scope
      when ContainerType
        value.scope
      else
        __typeof(value).as(TType).instance_scope
      end
    end

    # Primitive types have some restrictions on functionality. This method will
    # raise an appropriate error if the given value is a primitive.
    # If `operation` is given, it will be used as the error message.
    macro __disallow_primitives(value, operation=nil)
      if  {{value}}.is_a?(TInteger) || {{value}}.is_a?(TFloat) ||
          {{value}}.is_a?(TNil) || {{value}}.is_a?(TBoolean) ||
          {{value}}.is_a?(TString)
        raise {{operation || "Operation disallowed on primitive types"}}
      end
    end
  end
end