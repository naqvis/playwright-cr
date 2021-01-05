require "./channel_owner"
require "../dialog"

module Playwright
  private class DialogImpl < ChannelOwner
    include Dialog

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
      @handled = false
    end

    def accept(prompt_text : String?) : Nil
      @handled = true
      if prompt_text
        params = JSON::Any.new({"promptText" => JSON::Any.new(prompt_text)})
        send_message_no_wait("accept", params)
      else
        send_message_no_wait("accept")
      end
    end

    def default_value : String
      jsinitializer["defaultValue"].as_s
    end

    def dismiss : Nil
      @handled = true
      send_message_no_wait("dismiss")
    end

    def message : String
      jsinitializer["message"].as_s
    end

    def type : Type
      case jsinitializer["type"].as_s
      when "alert"        then Type::ALERT
      when "beforeunload" then Type::BEFOREUNLOAD
      when "confirm"      then Type::CONFIRM
      when "prompt"       then Type::PROMPT
      else
        raise PlaywrightException.new("uknown dialog type: #{jsinitializer["type"].as_s}")
      end
    end

    def handled?
      @handled
    end
  end
end
