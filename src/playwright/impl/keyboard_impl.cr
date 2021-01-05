require "../keyboard"

module Playwright
  private class KeyboardImpl
    include Keyboard
    getter page : ChannelOwner

    def initialize(@page)
    end

    def down(key : String) : Nil
      page.send_message("keyboardDown", JSON::Any.new({"key" => JSON::Any.new(key)}))
    end

    def insert_text(text : String) : Nil
      page.send_message("keyboardInsertText", JSON::Any.new({"text" => JSON::Any.new(text)}))
    end

    def press(key : String, delay : Int32?) : Nil
      params = {"key" => JSON::Any.new(key)}
      params["delay"] = JSON::Any.new(delay.not_nil!) if delay
      page.send_message("keyboardPress", JSON::Any.new(params))
    end

    def type(text : String, delay : Int32?) : Nil
      params = {"text" => JSON::Any.new(text)}
      params["delay"] = JSON::Any.new(delay.not_nil!) if delay
      page.send_message("keyboardType", JSON::Any.new(params))
    end

    def up(key : String) : Nil
      page.send_message("keyboardUp", JSON::Any.new({"key" => JSON::Any.new(key)}))
    end
  end
end
