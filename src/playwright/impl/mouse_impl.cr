require "../mouse"

module Playwright
  private class MouseImpl
    include Mouse

    getter page : ChannelOwner

    def initialize(@page)
    end

    def click(x : Int32, y : Int32, options : ClickOptions?) : Nil
      options ||= ClickOptions.new

      params = JSON.parse(options.to_json).as_h
      params["x"] = JSON::Any.new(x.to_i64)
      params["y"] = JSON::Any.new(y.to_i64)
      page.send_message("mouseClick", JSON::Any.new(params))
    end

    def dblclick(x : Int32, y : Int32, options : DblclickOptions?) : Nil
      options ||= DblclickOptions.new

      clickoptions = ClickOptions.from_json(options.to_json)
      clickoptions.click_count = 2
      click(x, y, clickoptions)
    end

    def down(options : DownOptions?) : Nil
      options ||= DownOptions.new
      page.send_message("mouseDown", JSON.parse(options.to_json))
    end

    def move(x : Int32, y : Int32, options : MoveOptions?) : Nil
      options ||= MoveOptions.new
      params = JSON.parse(options.to_json).as_h
      params["x"] = JSON::Any.new(x.to_i64)
      params["y"] = JSON::Any.new(y.to_i64)
      page.send_message("mouseMove", JSON::Any.new(params))
    end

    def up(options : UpOptions?) : Nil
      options ||= UpOptions.new
      page.send_message("mouseUp", JSON.parse(options.to_json))
    end
  end
end
