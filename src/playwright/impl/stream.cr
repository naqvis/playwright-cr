require "./channel_owner"
require "base64"

module Playwright
  private class Stream < ChannelOwner
    getter(stream : IO) { Reader.new(self) }

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
    end

    private class Reader < ::IO
      getter parent : ChannelOwner

      def initialize(@parent)
      end

      def read(slice : Bytes)
        return 0 if slice.empty?
        params = JSON::Any.new({"size" => JSON::Any.new(slice.size.to_i64)})
        json = parent.send_message("read", params)
        encoded = json["binary"].as_s
        return 0 if encoded.blank?
        buffer = Base64.decode(encoded)
        slice.copy_from(buffer.to_unsafe, buffer.size)
        buffer.size
      end

      def write(_slice : Bytes) : Nil
        raise PlaywrightException.new("Stream Reader cannot write")
      end
    end
  end
end
