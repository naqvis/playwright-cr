require "json"

module Playwright
  class AccessibilityNode
    include JSON::Serializable

    property role : String
    property name : String
    @[JSON::Field(key: "valueString")]
    property value_string : String?
    @[JSON::Field(key: "valueNumber")]
    property value_number : Number?
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
    property checked : CheckedState?
    property pressed : PressedState?
    property level : Int32?
    property valuemin : Float64?
    property valuemax : Float64?
    property autocomplete : String?
    property haspopup : String | Bool | Nil
    property invalid : String?
    property orientation : String?
    property children : Array(AccessibilityNode)?

    enum CheckedState
      CHECKED
      UNCHECKED
      MIXED

      def to_s
        super.downcase
      end

      def to_json(json : JSON::Builder)
        json.string(to_s)
      end
    end

    enum PressedState
      PRESSED
      RELEASED
      MIXED

      def to_s
        super.downcase
      end

      def to_json(json : JSON::Builder)
        json.string(to_s)
      end
    end
  end
end
