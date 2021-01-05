module Playwright
  struct DeviceDescriptor
    include JSON::Serializable

    @[JSON::Field(key: "userAgent")]
    getter user_agent : String

    @[JSON::Field(key: "deviceScaleFactor")]
    getter device_scale_factor : Float64

    @[JSON::Field(key: "isMobile")]
    getter is_mobile : Bool

    @[JSON::Field(key: "hasTouch")]
    getter has_touch : Bool

    @[JSON::Field(key: "hasTouch")]
    getter has_touch : Bool

    @[JSON::Field(key: "defaultBrowserType")]
    @default_browser_type : String

    property viewport : Viewport

    @[JSON::Field(ignore: true)]
    property playwright : PlaywrightImpl?

    def default_browser_type : BrowserType
      raise PlaywrightException.new("Playwright not initialized") if playwright.nil?
      case @default_browser_type
      when "chromium"
        playwright.chromium
      when "firefox"
        playwright.firefox
      when "webkit"
        playwright.webkit
      else
        raise PlaywrightException.new("Uknown browser type : #{@default_browser_type}")
      end
    end

    class Viewport
      include JSON::Serializable

      getter width : Int32
      getter height : Int32

      def initialize(@width, @height)
      end
    end
  end
end
