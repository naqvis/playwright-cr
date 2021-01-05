require "./channel_owner"
require "../consolemessage"

module Playwright
  private class ConsoleMessageImpl < ChannelOwner
    include ConsoleMessage

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
    end

    def args : Array(JSHandle)
      result = Array(JSHandle).new
      jsinitializer["args"].as_a.each do |arg|
        result << connection.get_existing_object(arg["guid"].as_s).as(JSHandleImpl)
      end
      result
    end

    def location : Location
      Location.from_json(jsinitializer["location"].to_json)
    end

    def text : String
      jsinitializer["text"].as_s
    end

    def type : String
      jsinitializer["type"].as_s
    end
  end
end
