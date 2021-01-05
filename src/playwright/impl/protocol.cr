require "json"

module Playwright
  private class Binary
  end

  private record Channel, guid : String do
    include JSON::Serializable
  end

  private record Metadata, stack : String do
    include JSON::Serializable
  end

  # :nodoc:
  class SerializedValue
    include JSON::Serializable
    property n : Number?
    property b : Bool?
    property s : String?
    # Possible values: { 'null, 'undefined, 'NaN, 'Infinity, '-Infinity, '-0 }
    property v : String?
    property d : String?

    class R
      include JSON::Serializable
      property p : String?
      property f : String?

      def initialize(@p = nil, @f = nil)
      end
    end

    property r : R?
    property a : Array(SerializedValue)?

    class O
      include JSON::Serializable
      property k : String?
      property v : SerializedValue?

      def initialize(@k = nil, @v = nil)
      end
    end

    property o : Array(O)?
    property h : Number?

    def initialize
    end
  end

  private class SerializedArgument
    include JSON::Serializable
    property value : SerializedValue?
    property handles : Array(Channel)?

    def initialize(@value = nil, @handles = nil)
    end
  end

  private class AXNode
    include JSON::Serializable
    property role : String?
    property name : String?
    @[JSON::Field(key: "valueString")]
    property value_string : String?
    property description : String?
    property keyshortcuts : String?
    property roledescription : String?
    property valuetext : String?
    property disabled : Bool?
    property expanded : Bool?
    property focused : Bool?
    property modal : Bool?
    property multiline : Bool?
    property multiselectable : Bool?
    property readonly : Bool?
    property required : Bool?
    property selected : Bool?
    # Possible values {'checked', 'unchecked', 'mixed'}
    property checked : String?
    # Possible values: { 'pressed, 'released, 'mixed }
    property pressed : String?
    property level : Number?
    property valuemin : Number?
    property valuemax : Number?
    property autocomplete : String?
    property haspopup : String?
    property invalid : String?
    property orientation : String?
    property children : Array(AXNode)?
  end

  # :nodoc:
  class SerializedError
    include JSON::Serializable

    # :nodoc:
    class Error
      include JSON::Serializable
      property message : String
      property name : String
      property stack : String

      def initialize(@message, @name, @stack)
      end

      def to_s
        "Error {
          message='#{message}'\n
          name='#{name}'\n
          stack='#{stack}'\n
          }
          "
      end
    end

    property error : Error?
    property value : SerializedValue?

    def initialize(@error = nil, @value = nil)
    end

    def to_s
      return error.to_s unless error.nil?
      "SerializedError{
        value=#{value}
        }"
    end
  end
end
