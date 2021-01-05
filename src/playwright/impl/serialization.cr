require "./protocol"
require "base64"

module Playwright
  module Serialization
    extend self

    def serialize_error(e : Exception) : SerializedError
      SerializedError.new(SerializedError::Error.new(
        message: e.message || "",
        name: e.class.name,
        stack: e.backtrace?.try &.join("\n") || ""
      ))
    end

    def serialize_value(value, handles : Array(JSHandle), depth : Int32) : SerializedValue
      raise PlaywrightException.new("Maximum argument depth exceeded") if depth > 100

      result = SerializedValue.new
      case value
      when JSHandle
        result.h = handles.size.to_i64
        handles << value.as(JSHandleImpl)
      when Nil
        result.v = "undefined"
      when Float
        if value.infinite?
          result.v = "Infinity"
        elsif value == -0.0
          result.v = "-0"
        elsif value.nan?
          result.v = "NaN"
        else
          result.n = value
        end
      when Bool
        result.b = value
      when Int
        result.n = value.to_i64
      when String
        result.s = value
      when Array
        arr = Array(SerializedValue).new
        value.each do |o|
          arr << serialize_value(o, handles, depth)
        end
        result.a = arr
      when Hash
        map = Array(SerializedValue::O).new
        value.each do |k, v|
          map << SerializedValue::O.new(k, serialize_value(v, handles, depth))
        end
        result.o = map
      when JSON::Any
        result = serialize_value(value.raw, handles, depth)
      else
        raise PlaywrightException.new("Unsupported type of argument: #{typeof(value)}")
      end
      result
    end

    def serialize_argument(arg : Any)
      result = SerializedArgument.new
      handles = Array(JSHandleImpl).new
      result.value = serialize_value(arg, handles, 0)
      result.handles = Array(Channel).new(handles.size) { |i|
        Channel.new(handles[i].guid)
      }
      result
    end

    def serialize_argument(args : Array(Any))
      return serialize_argument(args[0]) if args.size == 1
      result = SerializedArgument.new
      handles = Array(JSHandleImpl).new
      sv = SerializedValue.new
      sv.a = Array(SerializedValue).new
      args.each do |arg|
        sv.a.not_nil! << serialize_value(arg, handles, 0)
      end
      result.value = sv
      result.handles = Array(Channel).new(handles.size) { |i|
        Channel.new(handles[i].guid)
      }
      result
    end

    def deserialize(value : SerializedValue) : JSON::Any
      return JSON::Any.new(value.n) unless value.n.nil?
      return JSON::Any.new(value.b) unless value.b.nil?
      return JSON::Any.new(value.s) unless value.s.nil?
      if v = value.v
        case v
        when "undefined", "null"     then return JSON::Any.new(nil)
        when "Infinity", "-Infinity" then return JSON::Any.new(Float64::INFINITY)
        when "-0"                    then return JSON::Any.new(-0.0_f64)
        when "NaN"                   then return JSON::Any.new(Float64::NAN)
        else
          raise PlaywrightException.new("Unexpected value: #{v}")
        end
      end

      if a = value.a
        list = Array(JSON::Any).new
        a.each do |av|
          list << deserialize(av)
        end
        return JSON::Any.new(list)
      end

      if o = value.o
        map = Hash(String, JSON::Any).new
        o.each do |val|
          next if val.k.nil? || val.v.nil?
          map[val.k.not_nil!] = deserialize(val.v.not_nil!)
        end
        return JSON::Any.new(map)
      end

      raise PlaywrightException.new("Unexpected result: #{value.to_json}")
    end

    def to_protocol(handles : Array(ElementHandle))
      elems = JSON.build do |json|
        json.array do
          handles.each do |h|
            json.object do
              json.field "guid", h.as(ElementHandleImpl).guid
            end
          end
        end
      end
      JSON.parse(elems)
    end

    def to_protocol(map : Hash(String, String))
      elems = JSON.build do |json|
        json.array do
          map.each do |k, v|
            json.object do
              json.field "name", k
              json.field "value", v
            end
          end
        end
      end
      JSON.parse(elems)
    end

    def parse_stringlist(arr : JSON::Any)
      res = Array(String).new
      arr.as_a.each do |a|
        res << a.as_s
      end
      res
    end

    def to_json_array(files : Array(FileChooser::FilePayload))
      elems = JSON.build do |json|
        json.array do
          files.each do |file|
            json.object do
              json.field "name", file.name
              json.field "mimeType", file.mime_type
              json.field "buffer", Base64.strict_encode(file.buffer)
            end
          end
        end
      end
      JSON.parse(elems)
    end
  end
end

# :nodoc:
struct Slice(T)
  def to_json(json : JSON::Builder)
    json.string(Base64.strict_encode(self))
  end
end

# :nodoc:
class Regex
  def to_json(json : JSON::Builder)
    json.string(source)
  end
end
