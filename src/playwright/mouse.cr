require "json"

module Playwright
  # The Mouse class operates in main-frame CSS pixels relative to the top-left corner of the viewport.
  # Every `page` object has its own Mouse, accessible with page.mouse.
  #
  module Mouse
    enum Button
      LEFT
      MIDDLE
      RIGHT

      def to_s
        super.downcase
      end

      def to_json(json : JSON::Builder)
        json.string(to_s)
      end
    end

    class ClickOptions
      include JSON::Serializable
      # Defaults to `left`.
      @[JSON::Field(key: "button")]
      property button : Button?
      # defaults to 1. See UIEvent.detail.
      @[JSON::Field(key: "clickCount")]
      property click_count : Int32?
      # Time to wait between `mousedown` and `mouseup` in milliseconds. Defaults to 0.
      @[JSON::Field(key: "delay")]
      property delay : Int32?

      def initialize(@button = nil, @click_count = nil, @delay = nil)
      end
    end

    class DblclickOptions
      include JSON::Serializable
      # Defaults to `left`.
      @[JSON::Field(key: "button")]
      property button : Button?
      # Time to wait between `mousedown` and `mouseup` in milliseconds. Defaults to 0.
      @[JSON::Field(key: "delay")]
      property delay : Int32?

      def initialize(@button = nil, @delay = nil)
      end
    end

    class DownOptions
      include JSON::Serializable
      # Defaults to `left`.
      @[JSON::Field(key: "button")]
      property button : Button?
      # defaults to 1. See UIEvent.detail.
      @[JSON::Field(key: "clickCount")]
      property click_count : Int32?

      def initialize(@button = nil, @click_count = nil)
      end
    end

    class MoveOptions
      include JSON::Serializable
      # defaults to 1. Sends intermediate `mousemove` events.
      @[JSON::Field(key: "steps")]
      property steps : Int32?

      def initialize(@steps = nil)
      end
    end

    class UpOptions
      include JSON::Serializable
      # Defaults to `left`.
      @[JSON::Field(key: "button")]
      property button : Button?
      # defaults to 1. See UIEvent.detail.
      @[JSON::Field(key: "clickCount")]
      property click_count : Int32?

      def initialize(@button = nil, @click_count = nil)
      end
    end

    def click(x : Int32, y : Int32) : Nil
      click(x, y, nil)
    end

    # Shortcut for `mouse.move(x, y[, options])`, `mouse.down([options])`, `mouse.up([options])`.
    abstract def click(x : Int32, y : Int32, options : ClickOptions?) : Nil

    def dblclick(x : Int32, y : Int32) : Nil
      dblclick(x, y, nil)
    end

    # Shortcut for `mouse.move(x, y[, options])`, `mouse.down([options])`, `mouse.up([options])`, `mouse.down([options])` and `mouse.up([options])`.
    abstract def dblclick(x : Int32, y : Int32, options : DblclickOptions?) : Nil

    def down : Nil
      down(nil)
    end

    # Dispatches a `mousedown` event.
    abstract def down(options : DownOptions?) : Nil

    def move(x : Int32, y : Int32) : Nil
      move(x, y, nil)
    end

    # Dispatches a `mousemove` event.
    abstract def move(x : Int32, y : Int32, options : MoveOptions?) : Nil

    def up : Nil
      up(nil)
    end

    # Dispatches a `mouseup` event.
    abstract def up(options : UpOptions?) : Nil
  end
end
