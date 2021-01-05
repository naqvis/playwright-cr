require "./channel_owner"
require "../jshandle"

module Playwright
  private class JSHandleImpl < ChannelOwner
    include JSHandle

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
    end

    def as_element : ElementHandle?
      nil
    end

    def dispose : Nil
      send_message("dispose")
    end

    def evaluate(page_function : String, arg : Array(Any)?) : Any
      params = {
        "expression" => JSON::Any.new(page_function),
        "world"      => JSON::Any.new("main"),
        "isFunction" => JSON::Any.new(function_body?(page_function)),
        "arg"        => JSON.parse(Serialization.serialize_argument(arg).to_json),
      } of String => JSON::Any

      json = send_message("evaluateExpression", JSON::Any.new(params))
      value = SerializedValue.from_json(json["value"].to_json)
      Serialization.deserialize(value)
    end

    def evaluate_handle(page_function : String, arg : Array(Any)?) : JSHandle
      params = {
        "expression" => JSON::Any.new(page_function),
        "world"      => JSON::Any.new("main"),
        "isFunction" => JSON::Any.new(function_body?(page_function)),
        "arg"        => JSON.parse(Serialization.serialize_argument(arg).to_json),
      } of String => JSON::Any

      json = send_message("evaluateExpressionHandle", JSON::Any.new(params))
      connection.get_existing_object(json["handle"]["guid"].as_s).as(JSHandleImpl)
    end

    def get_properties : Hash(String, JSHandle)
      json = send_message("getPropertyList")
      result = Hash(String, JSHandle).new
      json["properties"].to_a.each do |e|
        result[e["name"].as_s] = connection.get_existing_object(e["value"]["guid"].as_s).as(JSHandleImpl)
      end
      result
    end

    def get_property(property_name : String) : JSHandle
      p = {"name" => property_name}
      json = send_message("getProperty", JSON.parse(p.to_json))
      connection.get_existing_object(json["handle"]["guid"].as_s).as(JSHandleImpl)
    end

    def json_value : Any
      json = send_message("jsonValue")
      Serialization.deserialize(SerializedValue.from_json(json["value"].to_json))
    end
  end
end
