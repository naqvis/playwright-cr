require "../touchscreen"

module Playwright
  private class TouchscreenImpl
    include Touchscreen

    getter page : ChannelOwner

    def initialize(@page)
    end

    def tap(x : Int32, y : Int32) : Nil
      params = {"x" => JSON::Any.new(x.to_i64),
                "y" => JSON::Any.new(y.to_i64)}
      page.send_message("touchscreenTap", JSON::Any.new(params))
    end
  end
end
