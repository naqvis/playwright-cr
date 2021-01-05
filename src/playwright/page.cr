require "path"
require "regex"
require "json"

module Playwright
  # Page provides methods to interact with a single tab in a Browser, or an extension background page in Chromium. One Browser instance might have multiple Page instances.
  # This example creates a page, navigates it to a URL, and then saves a screenshot:
  #
  # The Page class emits various events (described below) which can be handled using any of Node's native `EventEmitter` methods, such as `on`, `once` or `removeListener`.
  # This example logs a message for a single page `load` event:
  #
  # To unsubscribe from events use the `removeListener` method:
  #
  module Page
    class ViewPort
      include JSON::Serializable

      getter width : Int32
      getter height : Int32

      def initialize(@width, @height)
      end
    end

    module Function
      abstract def call(args : Array(Any)) : Any

      def call(*args : Any) : Any
        call(args.to_a)
      end
    end

    module Binding
      module Source
        abstract def context : BrowserContext?
        abstract def page : Page?
        abstract def frame : Frame
      end

      abstract def call(source : Source, args : Array(Any)) : Any

      def call(source : Source, *args : Any) : Any
        call(source, args.to_a)
      end
    end

    module Error
      abstract def message : String
      abstract def name : String
      abstract def stack : String
    end

    class WaitForEventOptions
      property timeout : Int32?
      property predicate : ((Event(EventType)) -> Bool) | Nil

      def initialize(@timeout = nil, @predicate = nil)
      end
    end

    enum EventType
      CLOSE
      CONSOLE
      CRASH
      DIALOG
      DOMCONTENTLOADED
      DOWNLOAD
      FILECHOOSER
      FRAMEATTACHED
      FRAMEDETACHED
      FRAMENAVIGATED
      LOAD
      PAGEERROR
      POPUP
      REQUEST
      REQUESTFAILED
      REQUESTFINISHED
      RESPONSE
      WEBSOCKET
      WORKER
    end

    abstract def add_listener(type : EventType, listener : Listener(EventType))
    abstract def remove_listener(type : EventType, listener : Listener(EventType))

    enum LoadState
      DOMCONTENTLOADED
      LOAD
      NETWORKIDLE

      def to_s
        super.downcase
      end

      def to_json(json : JSON::Builder)
        json.string(to_s)
      end
    end

    class AddScriptTagParams
      include JSON::Serializable
      # URL of a script to be added.
      @[JSON::Field(key: "url")]
      property url : String?
      # Path to the JavaScript file to be injected into frame. If `path` is a relative path, then it is resolved relative to the current working directory.
      @[JSON::Field(key: "path")]
      property path : String?
      # Raw JavaScript content to be injected into frame.
      @[JSON::Field(key: "content")]
      property content : String?
      # Script type. Use 'module' in order to load a Javascript ES6 module. See script for more details.
      @[JSON::Field(key: "type")]
      property type : String?

      def initialize(@url = nil, @path = nil, @content = nil, @type = nil)
      end
    end

    class AddStyleTagParams
      include JSON::Serializable
      # URL of the `<link>` tag.
      @[JSON::Field(key: "url")]
      property url : String?
      # Path to the CSS file to be injected into frame. If `path` is a relative path, then it is resolved relative to the current working directory.
      @[JSON::Field(key: "path")]
      property path : String?
      # Raw CSS content to be injected into frame.
      @[JSON::Field(key: "content")]
      property content : String?

      def initialize(@url = nil, @path = nil, @content = nil)
      end
    end

    class CheckOptions
      include JSON::Serializable
      # Whether to bypass the actionability checks. Defaults to `false`.
      @[JSON::Field(key: "force")]
      property force : Bool?
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@force = nil, @no_wait_after = nil, @timeout = nil)
      end
    end

    class ClickOptions
      include JSON::Serializable
      # Defaults to `left`.
      @[JSON::Field(key: "button")]
      property button : Mouse::Button?
      # defaults to 1. See UIEvent.detail.
      @[JSON::Field(key: "clickCount")]
      property click_count : Int32?
      # Time to wait between `mousedown` and `mouseup` in milliseconds. Defaults to 0.
      @[JSON::Field(key: "delay")]
      property delay : Int32?
      # A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element.
      @[JSON::Field(key: "position")]
      property position : Position?
      # Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used.
      @[JSON::Field(key: "modifiers")]
      property modifiers : Set(Keyboard::Modifier)?
      # Whether to bypass the actionability checks. Defaults to `false`.
      @[JSON::Field(key: "force")]
      property force : Bool?
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@button = nil, @click_count = nil, @delay = nil, @position = nil, @modifiers = nil, @force = nil, @no_wait_after = nil, @timeout = nil)
      end

      def with_position(position : Position) : ClickOptions
        self.position = position
        self
      end

      def with_position(x : Int32, y : Int32) : ClickOptions
        with_position(Position.new(x, y))
      end
    end

    class CloseOptions
      include JSON::Serializable
      # Defaults to `false`. Whether to run the before unload page handlers.
      @[JSON::Field(key: "runBeforeUnload")]
      property run_before_unload : Bool?

      def initialize(@run_before_unload = nil)
      end
    end

    class DblclickOptions
      include JSON::Serializable
      # Defaults to `left`.
      @[JSON::Field(key: "button")]
      property button : Mouse::Button?
      # Time to wait between `mousedown` and `mouseup` in milliseconds. Defaults to 0.
      @[JSON::Field(key: "delay")]
      property delay : Int32?
      # A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element.
      @[JSON::Field(key: "position")]
      property position : Position?
      # Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used.
      @[JSON::Field(key: "modifiers")]
      property modifiers : Set(Keyboard::Modifier)?
      # Whether to bypass the actionability checks. Defaults to `false`.
      @[JSON::Field(key: "force")]
      property force : Bool?
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@button = nil, @delay = nil, @position = nil, @modifiers = nil, @force = nil, @no_wait_after = nil, @timeout = nil)
      end

      def with_position(position : Position) : DblclickOptions
        self.position = position
        self
      end

      def with_position(x : Int32, y : Int32) : DblclickOptions
        with_position(Position.new(x, y))
      end
    end

    class DispatchEventOptions
      include JSON::Serializable
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
      end
    end

    class EmulateMediaParams
      include JSON::Serializable
      enum Media
        NULL
        PRINT
        SCREEN

        def to_s
          super.downcase
        end

        def to_json(json : JSON::Builder)
          json.string(to_s)
        end
      end
      # Changes the CSS media type of the page. The only allowed values are `'screen'`, `'print'` and `null`. Passing `null` disables CSS media emulation. Omitting `media` or passing `undefined` does not change the emulated value.
      @[JSON::Field(key: "media")]
      property media : Media?
      # Emulates `'prefers-colors-scheme'` media feature, supported values are `'light'`, `'dark'`, `'no-preference'`. Passing `null` disables color scheme emulation. Omitting `colorScheme` or passing `undefined` does not change the emulated value.
      @[JSON::Field(key: "colorScheme")]
      property color_scheme : ColorScheme?

      def initialize(@media = nil, @color_scheme = nil)
      end
    end

    class ExposeBindingOptions
      include JSON::Serializable
      # Whether to pass the argument as a handle, instead of passing by value. When passing a handle, only one argument is supported. When passing by value, multiple arguments are supported.
      @[JSON::Field(key: "handle")]
      property handle : Bool?

      def initialize(@handle = nil)
      end
    end

    class FillOptions
      include JSON::Serializable
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@no_wait_after = nil, @timeout = nil)
      end
    end

    class FocusOptions
      include JSON::Serializable
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
      end
    end

    class GetAttributeOptions
      include JSON::Serializable
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
      end
    end

    class GoBackOptions
      include JSON::Serializable
      # Maximum operation time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultNavigationTimeout(timeout)`, `browserContext.setDefaultTimeout(timeout)`, `page.setDefaultNavigationTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?
      # When to consider operation succeeded, defaults to `load`. Events can be either:
      #  - `'domcontentloaded'` - consider operation to be finished when the `DOMContentLoaded` event is fired.
      #  - `'load'` - consider operation to be finished when the `load` event is fired.
      #  - `'networkidle'` - consider operation to be finished when there are no network connections for at least `500` ms.
      @[JSON::Field(key: "waitUntil")]
      property wait_until : Frame::LoadState?

      def initialize(@timeout = nil, @wait_until = nil)
      end
    end

    class GoForwardOptions
      include JSON::Serializable
      # Maximum operation time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultNavigationTimeout(timeout)`, `browserContext.setDefaultTimeout(timeout)`, `page.setDefaultNavigationTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?
      # When to consider operation succeeded, defaults to `load`. Events can be either:
      #  - `'domcontentloaded'` - consider operation to be finished when the `DOMContentLoaded` event is fired.
      #  - `'load'` - consider operation to be finished when the `load` event is fired.
      #  - `'networkidle'` - consider operation to be finished when there are no network connections for at least `500` ms.
      @[JSON::Field(key: "waitUntil")]
      property wait_until : Frame::LoadState?

      def initialize(@timeout = nil, @wait_until = nil)
      end
    end

    class NavigateOptions
      include JSON::Serializable
      # Maximum operation time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultNavigationTimeout(timeout)`, `browserContext.setDefaultTimeout(timeout)`, `page.setDefaultNavigationTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?
      # When to consider operation succeeded, defaults to `load`. Events can be either:
      #  - `'domcontentloaded'` - consider operation to be finished when the `DOMContentLoaded` event is fired.
      #  - `'load'` - consider operation to be finished when the `load` event is fired.
      #  - `'networkidle'` - consider operation to be finished when there are no network connections for at least `500` ms.
      @[JSON::Field(key: "waitUntil")]
      property wait_until : Frame::LoadState?
      # Referer header value. If provided it will take preference over the referer header value set by `page.setExtraHTTPHeaders(headers)`.
      @[JSON::Field(key: "referer")]
      property referer : String?

      def initialize(@timeout = nil, @wait_until = nil, @referer = nil)
      end
    end

    class HoverOptions
      include JSON::Serializable
      # A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element.
      @[JSON::Field(key: "position")]
      property position : Position?
      # Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used.
      @[JSON::Field(key: "modifiers")]
      property modifiers : Set(Keyboard::Modifier)?
      # Whether to bypass the actionability checks. Defaults to `false`.
      @[JSON::Field(key: "force")]
      property force : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@position = nil, @modifiers = nil, @force = nil, @timeout = nil)
      end

      def with_position(position : Position) : HoverOptions
        self.position = position
        self
      end

      def with_position(x : Int32, y : Int32) : HoverOptions
        with_position(Position.new(x, y))
      end
    end

    class InnerHTMLOptions
      include JSON::Serializable
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
      end
    end

    class InnerTextOptions
      include JSON::Serializable
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
      end
    end

    class PdfOptions
      include JSON::Serializable

      class Margin
        include JSON::Serializable
        # Top margin, accepts values labeled with units. Defaults to `0`.
        @[JSON::Field(key: "top")]
        property top : String?
        # Right margin, accepts values labeled with units. Defaults to `0`.
        @[JSON::Field(key: "right")]
        property right : String?
        # Bottom margin, accepts values labeled with units. Defaults to `0`.
        @[JSON::Field(key: "bottom")]
        property bottom : String?
        # Left margin, accepts values labeled with units. Defaults to `0`.
        @[JSON::Field(key: "left")]
        property left : String?

        def initialize(@top = nil, @right = nil, @bottom = nil, @left = nil)
        end
      end

      # The file path to save the PDF to. If `path` is a relative path, then it is resolved relative to the current working directory. If no path is provided, the PDF won't be saved to the disk.
      @[JSON::Field(key: "path")]
      property path : Path?
      # Scale of the webpage rendering. Defaults to `1`. Scale amount must be between 0.1 and 2.
      @[JSON::Field(key: "scale")]
      property scale : Int32?
      # Display header and footer. Defaults to `false`.
      @[JSON::Field(key: "displayHeaderFooter")]
      property display_header_footer : Bool?
      # HTML template for the print header. Should be valid HTML markup with following classes used to inject printing values into them:
      #  - `'date'` formatted print date
      #  - `'title'` document title
      #  - `'url'` document location
      #  - `'pageNumber'` current page number
      #  - `'totalPages'` total pages in the document
      @[JSON::Field(key: "headerTemplate")]
      property header_template : String?
      # HTML template for the print footer. Should use the same format as the `headerTemplate`.
      @[JSON::Field(key: "footerTemplate")]
      property footer_template : String?
      # Print background graphics. Defaults to `false`.
      @[JSON::Field(key: "printBackground")]
      property print_background : Bool?
      # Paper orientation. Defaults to `false`.
      @[JSON::Field(key: "landscape")]
      property landscape : Bool?
      # Paper ranges to print, e.g., '1-5, 8, 11-13'. Defaults to the empty string, which means print all pages.
      @[JSON::Field(key: "pageRanges")]
      property page_ranges : String?
      # Paper format. If set, takes priority over `width` or `height` options. Defaults to 'Letter'.
      @[JSON::Field(key: "format")]
      property format : String?
      # Paper width, accepts values labeled with units.
      @[JSON::Field(key: "width")]
      property width : String?
      # Paper height, accepts values labeled with units.
      @[JSON::Field(key: "height")]
      property height : String?
      # Paper margins, defaults to none.
      @[JSON::Field(key: "margin")]
      property margin : Margin?
      # Give any CSS `@page` size declared in the page priority over what is declared in `width` and `height` or `format` options. Defaults to `false`, which will scale the content to fit the paper size.
      @[JSON::Field(key: "preferCSSPageSize")]
      property prefer_css_page_size : Bool?

      def initialize(@path = nil, @scale = nil, @display_header_footer = nil, @header_template = nil, @footer_template = nil, @print_background = nil, @landscape = nil, @page_ranges = nil, @format = nil, @width = nil, @height = nil, @margin = nil, @prefer_css_page_size = nil)
      end
    end

    class PressOptions
      include JSON::Serializable
      # Time to wait between `keydown` and `keyup` in milliseconds. Defaults to 0.
      @[JSON::Field(key: "delay")]
      property delay : Int32?
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@delay = nil, @no_wait_after = nil, @timeout = nil)
      end
    end

    class ReloadOptions
      include JSON::Serializable
      # Maximum operation time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultNavigationTimeout(timeout)`, `browserContext.setDefaultTimeout(timeout)`, `page.setDefaultNavigationTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?
      # When to consider operation succeeded, defaults to `load`. Events can be either:
      #  - `'domcontentloaded'` - consider operation to be finished when the `DOMContentLoaded` event is fired.
      #  - `'load'` - consider operation to be finished when the `load` event is fired.
      #  - `'networkidle'` - consider operation to be finished when there are no network connections for at least `500` ms.
      @[JSON::Field(key: "waitUntil")]
      property wait_until : Frame::LoadState?

      def initialize(@timeout = nil, @wait_until = nil)
      end
    end

    class ScreenshotOptions
      include JSON::Serializable
      enum Type
        JPEG
        PNG

        def to_s
          super.downcase
        end

        def to_json(json : JSON::Builder)
          json.string(to_s)
        end
      end

      class Clip
        include JSON::Serializable
        # x-coordinate of top-left corner of clip area
        @[JSON::Field(key: "x")]
        property x : Int32
        # y-coordinate of top-left corner of clip area
        @[JSON::Field(key: "y")]
        property y : Int32
        # width of clipping area
        @[JSON::Field(key: "width")]
        property width : Int32
        # height of clipping area
        @[JSON::Field(key: "height")]
        property height : Int32

        def initialize(@x, @y, @width, @height)
        end
      end

      # The file path to save the image to. The screenshot type will be inferred from file extension. If `path` is a relative path, then it is resolved relative to the current working directory. If no path is provided, the image won't be saved to the disk.
      @[JSON::Field(key: "path")]
      property path : Path?
      # Specify screenshot type, defaults to `png`.
      @[JSON::Field(key: "type")]
      property type : Type?
      # The quality of the image, between 0-100. Not applicable to `png` images.
      @[JSON::Field(key: "quality")]
      property quality : Int32?
      # When true, takes a screenshot of the full scrollable page, instead of the currently visible viewport. Defaults to `false`.
      @[JSON::Field(key: "fullPage")]
      property full_page : Bool?
      # An object which specifies clipping of the resulting image. Should have the following fields:
      @[JSON::Field(key: "clip")]
      property clip : Clip?
      # Hides default white background and allows capturing screenshots with transparency. Not applicable to `jpeg` images. Defaults to `false`.
      @[JSON::Field(key: "omitBackground")]
      property omit_background : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@path = nil, @type = nil, @quality = nil, @full_page = nil, @clip = nil, @omit_background = nil, @timeout = nil)
      end
    end

    class SelectOptionOptions
      include JSON::Serializable
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@no_wait_after = nil, @timeout = nil)
      end
    end

    class SetContentOptions
      include JSON::Serializable
      # Maximum operation time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultNavigationTimeout(timeout)`, `browserContext.setDefaultTimeout(timeout)`, `page.setDefaultNavigationTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?
      # When to consider operation succeeded, defaults to `load`. Events can be either:
      #  - `'domcontentloaded'` - consider operation to be finished when the `DOMContentLoaded` event is fired.
      #  - `'load'` - consider operation to be finished when the `load` event is fired.
      #  - `'networkidle'` - consider operation to be finished when there are no network connections for at least `500` ms.
      @[JSON::Field(key: "waitUntil")]
      property wait_until : Frame::LoadState?

      def initialize(@timeout = nil, @wait_until = nil)
      end
    end

    class SetInputFilesOptions
      include JSON::Serializable
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@no_wait_after = nil, @timeout = nil)
      end
    end

    class TapOptions
      include JSON::Serializable

      class Position
        include JSON::Serializable
        @[JSON::Field(key: "x")]
        property x : Int32
        @[JSON::Field(key: "y")]
        property y : Int32

        def initialize(@x, @y)
        end
      end

      # A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element.
      @[JSON::Field(key: "position")]
      property position : Position?
      # Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used.
      @[JSON::Field(key: "modifiers")]
      property modifiers : Set(Keyboard::Modifier)?
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Whether to bypass the actionability checks. Defaults to `false`.
      @[JSON::Field(key: "force")]
      property force : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@position = nil, @modifiers = nil, @no_wait_after = nil, @force = nil, @timeout = nil)
      end
    end

    class TextContentOptions
      include JSON::Serializable
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
      end
    end

    class TypeOptions
      include JSON::Serializable
      # Time to wait between key presses in milliseconds. Defaults to 0.
      @[JSON::Field(key: "delay")]
      property delay : Int32?
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@delay = nil, @no_wait_after = nil, @timeout = nil)
      end
    end

    class UncheckOptions
      include JSON::Serializable
      # Whether to bypass the actionability checks. Defaults to `false`.
      @[JSON::Field(key: "force")]
      property force : Bool?
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@force = nil, @no_wait_after = nil, @timeout = nil)
      end
    end

    class WaitForFunctionOptions
      include JSON::Serializable
      # If `polling` is `'raf'`, then `pageFunction` is constantly executed in `requestAnimationFrame` callback. If `polling` is a number, then it is treated as an interval in milliseconds at which the function would be executed. Defaults to `raf`.

      @[JSON::Field(key: "pollingInterval")]
      property polling : Int32?

      # maximum time to wait for in milliseconds. Defaults to `30000` (30 seconds). Pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)`.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@polling = nil, @timeout = nil)
      end

      def with_request_animation_frame
        @polling = nil
        self
      end

      def with_polling_interval(millis : Int32)
        @polling = millis
        self
      end
    end

    class WaitForLoadStateOptions
      include JSON::Serializable
      # Maximum operation time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultNavigationTimeout(timeout)`, `browserContext.setDefaultTimeout(timeout)`, `page.setDefaultNavigationTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
      end
    end

    class WaitForNavigationOptions
      include JSON::Serializable
      # Maximum operation time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultNavigationTimeout(timeout)`, `browserContext.setDefaultTimeout(timeout)`, `page.setDefaultNavigationTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?
      # A glob pattern, regex pattern or predicate receiving URL to match while waiting for the navigation.

      @[JSON::Field(key: "url")]
      property url : String | Regex | Proc(String, Bool) | Nil?
      @[JSON::Field(ignore: true)]
      getter(glob : String?) { url.as?(String) }
      @[JSON::Field(ignore: true)]
      getter(pattern : Regex?) { url.as?(Regex) }
      @[JSON::Field(ignore: true)]
      getter(predicate : (String -> Bool)?) { url.as?(Proc(String, Bool)) }
      # When to consider operation succeeded, defaults to `load`. Events can be either:
      #  - `'domcontentloaded'` - consider operation to be finished when the `DOMContentLoaded` event is fired.
      #  - `'load'` - consider operation to be finished when the `load` event is fired.
      #  - `'networkidle'` - consider operation to be finished when there are no network connections for at least `500` ms.
      @[JSON::Field(key: "waitUntil")]
      property wait_until : Frame::LoadState?

      def initialize(@timeout = nil, @url = nil, @wait_until = nil)
      end

      def glob=(val : String?)
        @url = val
      end

      def pattern=(val : Regex?)
        @url = val
      end

      def predicate=(val : (String -> Bool)?)
        @url = val
      end
    end

    class WaitForRequestOptions
      include JSON::Serializable
      # Maximum wait time in milliseconds, defaults to 30 seconds, pass `0` to disable the timeout. The default value can be changed by using the `page.setDefaultTimeout(timeout)` method.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
      end
    end

    class WaitForResponseOptions
      include JSON::Serializable
      # Maximum wait time in milliseconds, defaults to 30 seconds, pass `0` to disable the timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
      end
    end

    class WaitForSelectorOptions
      include JSON::Serializable
      enum State
        ATTACHED
        DETACHED
        HIDDEN
        VISIBLE

        def to_s
          super.downcase
        end

        def to_json(json : JSON::Builder)
          json.string(to_s)
        end
      end
      # Defaults to `'visible'`. Can be either:
      #  - `'attached'` - wait for element to be present in DOM.
      #  - `'detached'` - wait for element to not be present in DOM.
      #  - `'visible'` - wait for element to have non-empty bounding box and no `visibility:hidden`. Note that element without any content or with `display:none` has an empty bounding box and is not considered visible.
      #  - `'hidden'` - wait for element to be either detached from DOM, or have an empty bounding box or `visibility:hidden`. This is opposite to the `'visible'` option.
      @[JSON::Field(key: "state")]
      property state : State?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@state = nil, @timeout = nil)
      end
    end

    # The method finds an element matching the specified selector within the page. If no elements match the selector, the return value resolves to `null`.
    # Shortcut for main frame's `frame.$(selector)`.
    abstract def query_selector(selector : String) : ElementHandle?
    # The method finds all elements matching the specified selector within the page. If no elements match the selector, the return value resolves to `[]`.
    # Shortcut for main frame's `frame.$$(selector)`.
    abstract def query_selector_all(selector : String) : Array(ElementHandle)

    def eval_on_selector(selector : String, page_function : String) : Any
      eval_on_selector(selector, page_function, nil)
    end

    def eval_on_selector(selector : String, page_function : String, *arg : Any) : Any
      eval_on_selector(selector, page_function, arg.to_a)
    end

    # The method finds an element matching the specified selector within the page and passes it as a first argument to `pageFunction`. If no elements match the selector, the method throws an error. Returns the value of `pageFunction`.
    # If `pageFunction` returns a Promise, then `page.$eval(selector, pageFunction[, arg])` would wait for the promise to resolve and return its value.
    # Examples:
    #
    # Shortcut for main frame's `frame.$eval(selector, pageFunction[, arg])`.
    abstract def eval_on_selector(selector : String, page_function : String, arg : Array(Any)?) : Any

    def eval_on_selector_all(selector : String, page_function : String) : Any
      eval_on_selector_all(selector, page_function, nil)
    end

    def eval_on_selector_all(selector : String, page_function : String, *arg : Any) : Any
      eval_on_selector_all(selector, page_function, arg.to_a)
    end

    # The method finds all elements matching the specified selector within the page and passes an array of matched elements as a first argument to `pageFunction`. Returns the result of `pageFunction` invocation.
    # If `pageFunction` returns a Promise, then `page.$$eval(selector, pageFunction[, arg])` would wait for the promise to resolve and return its value.
    # Examples:
    #
    abstract def eval_on_selector_all(selector : String, page_function : String, arg : Array(Any)?) : Any

    def add_init_script(script : String) : Nil
      add_init_script(script, nil)
    end

    # Adds a script which would be evaluated in one of the following scenarios:
    #
    # Whenever the page is navigated.
    # Whenever the child frame is attached or navigated. In this case, the script is evaluated in the context of the newly attached frame.
    #
    # The script is evaluated after the document was created but before any of its scripts were run. This is useful to amend the JavaScript environment, e.g. to seed `Math.random`.
    # An example of overriding `Math.random` before the page loads:
    #
    #
    # **NOTE** The order of evaluation of multiple scripts installed via `browserContext.addInitScript(script[, arg])` and `page.addInitScript(script[, arg])` is not defined.
    abstract def add_init_script(script : String, arg : Any) : Nil
    # Adds a `<script>` tag into the page with the desired url or content. Returns the added tag when the script's onload fires or when the script content was injected into frame.
    # Shortcut for main frame's `frame.addScriptTag(params)`.
    abstract def add_script_tag(params : AddScriptTagParams) : ElementHandle
    # Adds a `<link rel="stylesheet">` tag into the page with the desired url or a `<style type="text/css">` tag with the content. Returns the added tag when the stylesheet's onload fires or when the CSS content was injected into frame.
    # Shortcut for main frame's `frame.addStyleTag(params)`.
    abstract def add_style_tag(params : AddStyleTagParams) : ElementHandle
    # Brings page to front (activates tab).
    abstract def bring_to_front : Nil

    def check(selector : String) : Nil
      check(selector, nil)
    end

    # This method checks an element matching `selector` by performing the following steps:
    #
    # Find an element match matching `selector`. If there is none, wait until a matching element is attached to the DOM.
    # Ensure that matched element is a checkbox or a radio input. If not, this method rejects. If the element is already checked, this method returns immediately.
    # Wait for actionability checks on the matched element, unless `force` option is set. If the element is detached during the checks, the whole action is retried.
    # Scroll the element into view if needed.
    # Use page.mouse to click in the center of the element.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    # Ensure that the element is now checked. If not, this method rejects.
    #
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    # Shortcut for main frame's `frame.check(selector[, options])`.
    abstract def check(selector : String, options : CheckOptions?) : Nil

    def click(selector : String) : Nil
      click(selector, nil)
    end

    # This method clicks an element matching `selector` by performing the following steps:
    #
    # Find an element match matching `selector`. If there is none, wait until a matching element is attached to the DOM.
    # Wait for actionability checks on the matched element, unless `force` option is set. If the element is detached during the checks, the whole action is retried.
    # Scroll the element into view if needed.
    # Use page.mouse to click in the center of the element, or the specified `position`.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    #
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    # Shortcut for main frame's `frame.click(selector[, options])`.
    abstract def click(selector : String, options : ClickOptions?) : Nil

    def close : Nil
      close(nil)
    end

    # If `runBeforeUnload` is `false`, does not run any unload handlers and waits for the page to be closed. If `runBeforeUnload` is `true` the method will run unload handlers, but will **not** wait for the page to close.
    # By default, `page.close()` **does not** run `beforeunload` handlers.
    #
    # **NOTE** if `runBeforeUnload` is passed as true, a `beforeunload` dialog might be summoned
    # and should be handled manually via page.on('dialog') event.
    abstract def close(options : CloseOptions?) : Nil
    # Gets the full HTML contents of the page, including the doctype.
    abstract def content : String
    # Get the browser context that the page belongs to.
    abstract def context : BrowserContext

    def dblclick(selector : String) : Nil
      dblclick(selector, nil)
    end

    # This method double clicks an element matching `selector` by performing the following steps:
    #
    # Find an element match matching `selector`. If there is none, wait until a matching element is attached to the DOM.
    # Wait for actionability checks on the matched element, unless `force` option is set. If the element is detached during the checks, the whole action is retried.
    # Scroll the element into view if needed.
    # Use page.mouse to double click in the center of the element, or the specified `position`.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set. Note that if the first click of the `dblclick()` triggers a navigation event, this method will reject.
    #
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    #
    # **NOTE** `page.dblclick()` dispatches two `click` events and a single `dblclick` event.
    #
    # Shortcut for main frame's `frame.dblclick(selector[, options])`.
    abstract def dblclick(selector : String, options : DblclickOptions?) : Nil

    def dispatch_event(selector : String, type : String, event_init : Array(Any)?) : Nil
      dispatch_event(selector, type, event_init, nil)
    end

    def dispatch_event(selector : String, type : String) : Nil
      dispatch_event(selector, type, nil)
    end

    def dispatch_event(selector : String, type : String, *event_init : Any) : Nil
      dispatch_event(selector, type, event_init.to_a)
    end

    # The snippet below dispatches the `click` event on the element. Regardless of the visibility state of the elment, `click` is dispatched. This is equivalend to calling element.click().
    #
    # Under the hood, it creates an instance of an event based on the given `type`, initializes it with `eventInit` properties and dispatches it on the element. Events are `composed`, `cancelable` and bubble by default.
    # Since `eventInit` is event-specific, please refer to the events documentation for the lists of initial properties:
    #
    # DragEvent
    # FocusEvent
    # KeyboardEvent
    # MouseEvent
    # PointerEvent
    # TouchEvent
    # Event
    #
    # You can also specify `JSHandle` as the property value if you want live objects to be passed into the event:
    #
    abstract def dispatch_event(selector : String, type : String, event_init : Array(Any)?, options : DispatchEventOptions?) : Nil
    abstract def emulate_media(params : EmulateMediaParams) : Nil

    def evaluate(page_function : String) : Any
      evaluate(page_function, nil)
    end

    def evaluate(page_function : String, *arg : Any) : Any
      evaluate(page_function, arg.to_a)
    end

    # Returns the value of the `pageFunction` invacation.
    # If the function passed to the `page.evaluate` returns a Promise, then `page.evaluate` would wait for the promise to resolve and return its value.
    # If the function passed to the `page.evaluate` returns a non-Serializable value, then `page.evaluate` resolves to `undefined`. DevTools Protocol also supports transferring some additional values that are not serializable by `JSON`: `-0`, `NaN`, `Infinity`, `-Infinity`, and bigint literals.
    # Passing argument to `pageFunction`:
    #
    # A string can also be passed in instead of a function:
    #
    # ElementHandle instances can be passed as an argument to the `page.evaluate`:
    #
    # Shortcut for main frame's `frame.evaluate(pageFunction[, arg])`.
    abstract def evaluate(page_function : String, arg : Array(Any)?) : Any

    def evaluate_handle(page_function : String) : JSHandle
      evaluate_handle(page_function, nil)
    end

    def evaluate_handle(page_function : String, *arg : Any) : JSHandle
      evaluate_handle(page_function, arg.to_a)
    end

    # Returns the value of the `pageFunction` invacation as in-page object (JSHandle).
    # The only difference between `page.evaluate` and `page.evaluateHandle` is that `page.evaluateHandle` returns in-page object (JSHandle).
    # If the function passed to the `page.evaluateHandle` returns a Promise, then `page.evaluateHandle` would wait for the promise to resolve and return its value.
    # A string can also be passed in instead of a function:
    #
    # JSHandle instances can be passed as an argument to the `page.evaluateHandle`:
    #
    abstract def evaluate_handle(page_function : String, arg : Array(Any)?) : JSHandle

    def expose_binding(name : String, playwright_binding : Binding) : Nil
      expose_binding(name, playwright_binding, nil)
    end

    # The method adds a function called `name` on the `window` object of every frame in this page. When called, the function executes `playwrightBinding` and returns a Promise which resolves to the return value of `playwrightBinding`. If the `playwrightBinding` returns a Promise, it will be awaited.
    # The first argument of the `playwrightBinding` function contains information about the caller: `{ browserContext: BrowserContext, page: Page, frame: Frame }`.
    # See `browserContext.exposeBinding(name, playwrightBinding[, options])` for the context-wide version.
    #
    # **NOTE** Functions installed via `page.exposeBinding` survive navigations.
    #
    # An example of exposing page URL to all frames in a page:
    #
    # An example of passing an element handle:
    #
    abstract def expose_binding(name : String, playwright_binding : Binding, options : ExposeBindingOptions?) : Nil
    # The method adds a function called `name` on the `window` object of every frame in the page. When called, the function executes `playwrightFunction` and returns a Promise which resolves to the return value of `playwrightFunction`.
    # If the `playwrightFunction` returns a Promise, it will be awaited.
    # See `browserContext.exposeFunction(name, playwrightFunction)` for context-wide exposed function.
    #
    # **NOTE** Functions installed via `page.exposeFunction` survive navigations.
    #
    # An example of adding an `md5` function to the page:
    #
    # An example of adding a `window.readfile` function to the page:
    #
    abstract def expose_function(name : String, playwright_function : Function) : Nil

    def fill(selector : String, value : String) : Nil
      fill(selector, value, nil)
    end

    # This method waits for an element matching `selector`, waits for actionability checks, focuses the element, fills it and triggers an `input` event after filling. If the element matching `selector` is not an `<input>`, `<textarea>` or `[contenteditable]` element, this method throws an error. Note that you can pass an empty string to clear the input field.
    # To send fine-grained keyboard events, use `page.type(selector, text[, options])`.
    # Shortcut for main frame's `frame.fill(selector, value[, options])`
    abstract def fill(selector : String, value : String, options : FillOptions?) : Nil

    def focus(selector : String) : Nil
      focus(selector, nil)
    end

    # This method fetches an element with `selector` and focuses it. If there's no element matching `selector`, the method waits until a matching element appears in the DOM.
    # Shortcut for main frame's `frame.focus(selector[, options])`.
    abstract def focus(selector : String, options : FocusOptions?) : Nil
    abstract def frame_by_name(name : String) : Frame?
    abstract def frame_by_url(glob : String) : Frame?
    abstract def frame_by_url(pattern : Regex) : Frame?
    # Returns frame matching the specified criteria. Either `name` or `url` must be specified.
    #
    #
    abstract def frame_by_url(predicate : (String) -> Bool) : Frame?
    # An array of all frames attached to the page.
    abstract def frames : Array(Frame)

    def get_attribute(selector : String, name : String) : String?
      get_attribute(selector, name, nil)
    end

    # Returns element attribute value.
    abstract def get_attribute(selector : String, name : String, options : GetAttributeOptions?) : String?

    def go_back : Response?
      go_back(nil)
    end

    # Returns the main resource response. In case of multiple redirects, the navigation will resolve with the response of the last redirect. If can not go back, returns `null`.
    # Navigate to the previous page in history.
    abstract def go_back(options : GoBackOptions?) : Response?

    def go_forward : Response?
      go_forward(nil)
    end

    # Returns the main resource response. In case of multiple redirects, the navigation will resolve with the response of the last redirect. If can not go forward, returns `null`.
    # Navigate to the next page in history.
    abstract def go_forward(options : GoForwardOptions?) : Response?

    def goto(url : String) : Response?
      goto(url, nil)
    end

    # Returns the main resource response. In case of multiple redirects, the navigation will resolve with the response of the last redirect.
    # `page.goto` will throw an error if:
    #
    # there's an SSL error (e.g. in case of self-signed certificates).
    # target URL is invalid.
    # the `timeout` is exceeded during navigation.
    # the remote server does not respond or is unreachable.
    # the main resource failed to load.
    #
    # `page.goto` will not throw an error when any valid HTTP status code is returned by the remote server, including 404 "Not Found" and 500 "Internal Server Error".  The status code for such responses can be retrieved by calling `response.status()`.
    #
    # **NOTE** `page.goto` either throws an error or returns a main resource response. The only exceptions are navigation to `about:blank` or navigation to the same URL with a different hash, which would succeed and return `null`.
    # **NOTE** Headless mode doesn't support navigation to a PDF document. See the upstream issue.
    #
    # Shortcut for main frame's `frame.goto(url[, options])`
    abstract def goto(url : String, options : NavigateOptions?) : Response?

    def hover(selector : String) : Nil
      hover(selector, nil)
    end

    # This method hovers over an element matching `selector` by performing the following steps:
    #
    # Find an element match matching `selector`. If there is none, wait until a matching element is attached to the DOM.
    # Wait for actionability checks on the matched element, unless `force` option is set. If the element is detached during the checks, the whole action is retried.
    # Scroll the element into view if needed.
    # Use page.mouse to hover over the center of the element, or the specified `position`.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    #
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    # Shortcut for main frame's `frame.hover(selector[, options])`.
    abstract def hover(selector : String, options : HoverOptions?) : Nil

    def inner_html(selector : String) : String
      inner_html(selector, nil)
    end

    # Returns `element.innerHTML`.
    abstract def inner_html(selector : String, options : InnerHTMLOptions?) : String

    def inner_text(selector : String) : String
      inner_text(selector, nil)
    end

    # Returns `element.innerText`.
    abstract def inner_text(selector : String, options : InnerTextOptions?) : String
    # Indicates that the page has been closed.
    abstract def is_closed : Bool
    # The page's main frame. Page is guaranteed to have a main frame which persists during navigations.
    abstract def main_frame : Frame
    # Returns the opener for popup pages and `null` for others. If the opener has been closed already the returns `null`.
    abstract def opener : Page?

    def pdf : Bytes
      pdf(nil)
    end

    # Returns the PDF buffer.
    #
    # **NOTE** Generating a pdf is currently only supported in Chromium headless.
    #
    # `page.pdf()` generates a pdf of the page with `print` css media. To generate a pdf with `screen` media, call `page.emulateMedia(params)` before calling `page.pdf()`:
    #
    # **NOTE** By default, `page.pdf()` generates a pdf with modified colors for printing. Use the `-webkit-print-color-adjust` property to force rendering of exact colors.
    #
    #
    # The `width`, `height`, and `margin` options accept values labeled with units. Unlabeled values are treated as pixels.
    # A few examples:
    #
    # `page.pdf({width: 100})` - prints with width set to 100 pixels
    # `page.pdf({width: '100px'})` - prints with width set to 100 pixels
    # `page.pdf({width: '10cm'})` - prints with width set to 10 centimeters.
    #
    # All possible units are:
    #
    # `px` - pixel
    # `in` - inch
    # `cm` - centimeter
    # `mm` - millimeter
    #
    # The `format` options are:
    #
    # `Letter`: 8.5in x 11in
    # `Legal`: 8.5in x 14in
    # `Tabloid`: 11in x 17in
    # `Ledger`: 17in x 11in
    # `A0`: 33.1in x 46.8in
    # `A1`: 23.4in x 33.1in
    # `A2`: 16.54in x 23.4in
    # `A3`: 11.7in x 16.54in
    # `A4`: 8.27in x 11.7in
    # `A5`: 5.83in x 8.27in
    # `A6`: 4.13in x 5.83in
    #
    #
    # **NOTE** `headerTemplate` and `footerTemplate` markup have the following limitations:
    #
    # Script tags inside templates are not evaluated.
    # Page styles are not visible inside templates.
    abstract def pdf(options : PdfOptions?) : Bytes

    def press(selector : String, key : String) : Nil
      press(selector, key, nil)
    end

    # Focuses the element, and then uses `keyboard.down(key)` and `keyboard.up(key)`.
    # `key` can specify the intended keyboardEvent.key value or a single character to generate the text for. A superset of the `key` values can be found here. Examples of the keys are:
    # `F1` - `F12`, `Digit0`- `Digit9`, `KeyA`- `KeyZ`, `Backquote`, `Minus`, `Equal`, `Backslash`, `Backspace`, `Tab`, `Delete`, `Escape`, `ArrowDown`, `End`, `Enter`, `Home`, `Insert`, `PageDown`, `PageUp`, `ArrowRight`, `ArrowUp`, etc.
    # Following modification shortcuts are also suported: `Shift`, `Control`, `Alt`, `Meta`, `ShiftLeft`.
    # Holding down `Shift` will type the text that corresponds to the `key` in the upper case.
    # If `key` is a single character, it is case-sensitive, so the values `a` and `A` will generate different respective texts.
    # Shortcuts such as `key: "Control+o"` or `key: "Control+Shift+T"` are supported as well. When speficied with the modifier, modifier is pressed and being held while the subsequent key is being pressed.
    #
    abstract def press(selector : String, key : String, options : PressOptions?) : Nil

    def reload : Response?
      reload(nil)
    end

    # Returns the main resource response. In case of multiple redirects, the navigation will resolve with the response of the last redirect.
    abstract def reload(options : ReloadOptions?) : Response?
    abstract def route(url : String, handler : Consumer(Route))
    abstract def route(url : Regex, handler : Consumer(Route))
    # Routing provides the capability to modify network requests that are made by a page.
    # Once routing is enabled, every request matching the url pattern will stall unless it's continued, fulfilled or aborted.
    #
    # **NOTE** The handler will only be called for the first url if the response is a redirect.
    #
    # An example of a naïve handler that aborts all image requests:
    #
    # or the same snippet using a regex pattern instead:
    #
    # Page routes take precedence over browser context routes (set up with `browserContext.route(url, handler)`) when request matches both handlers.
    #
    # **NOTE** Enabling routing disables http cache.
    abstract def route(url : (String) -> Bool, handler : Consumer(Route))

    def screenshot : Bytes
      screenshot(nil)
    end

    # Returns the buffer with the captured screenshot.
    #
    # **NOTE** Screenshots take at least 1/6 second on Chromium OS X and Chromium Windows. See https://crbug.com/741689 for discussion.
    abstract def screenshot(options : ScreenshotOptions?) : Bytes

    def select_option(selector : String, value : String)
      select_option(selector, value, nil)
    end

    def select_option(selector : String, value : String, options : SelectOptionOptions?)
      select_option(selector, [value], nil)
    end

    def select_option(selector : String, values : Array(String))
      select_option(selector, values, nil)
    end

    def select_option(selector : String, values : Array(String), options : SelectOptionOptions?)
      if values.size == 0
        return select_option(selector, ElementHandle::SelectOption.new, options)
      end
      select_option(selector, values.map { |v| ElementHandle::SelectOption.new(v) }.to_a, options)
    end

    def select_option(selector : String, value : ElementHandle::SelectOption?)
      select_option(selector, value, nil)
    end

    def select_option(selector : String, value : ElementHandle::SelectOption?, options : SelectOptionOptions?)
      select_option(selector, value.nil? ? nil : [value], options)
    end

    def select_option(selector : String, values : Array(ElementHandle::SelectOption)?)
      select_option(selector, values, nil)
    end

    abstract def select_option(selector : String, values : Array(ElementHandle::SelectOption)?, options : SelectOptionOptions?)

    def select_option(selector : String, value : ElementHandle?)
      select_option(selector, value, nil)
    end

    def select_option(selector : String, value : ElementHandle?, options : SelectOptionOptions?)
      select_option(selector, value.nil? ? nil : [value], options)
    end

    def select_option(selector : String, values : Array(ElementHandle)?)
      select_option(selector, values, nil)
    end

    # Returns the array of option values that have been successfully selected.
    # Triggers a `change` and `input` event once all the provided options have been selected. If there's no `<select>` element matching `selector`, the method throws an error.
    #
    # Shortcut for main frame's `frame.selectOption(selector, values[, options])`

    abstract def select_option(selector : String, values : Array(ElementHandle)?, options : SelectOptionOptions?)

    def set_content(html : String) : Nil
      set_content(html, nil)
    end

    abstract def set_content(html : String, options : SetContentOptions?) : Nil
    # This setting will change the default maximum navigation time for the following methods and related shortcuts:
    #
    # `page.goBack([options])`
    # `page.goForward([options])`
    # `page.goto(url[, options])`
    # `page.reload([options])`
    # `page.setContent(html[, options])`
    # `page.waitForNavigation([options])`
    #
    #
    # **NOTE** `page.setDefaultNavigationTimeout(timeout)` takes priority over `page.setDefaultTimeout(timeout)`, `browserContext.setDefaultTimeout(timeout)` and `browserContext.setDefaultNavigationTimeout(timeout)`.
    abstract def set_default_navigation_timeout(timeout : Int32) : Nil
    # This setting will change the default maximum time for all the methods accepting `timeout` option.
    #
    # **NOTE** `page.setDefaultNavigationTimeout(timeout)` takes priority over `page.setDefaultTimeout(timeout)`.
    abstract def set_default_timeout(timeout : Int32) : Nil
    # The extra HTTP headers will be sent with every request the page initiates.
    #
    # **NOTE** page.setExtraHTTPHeaders does not guarantee the order of headers in the outgoing requests.
    abstract def set_extra_http_headers(headers : Hash(String, String)) : Nil

    def set_input_files(selector : String, file : Path)
      set_input_files(selector, file, nil)
    end

    def set_input_files(selector : String, file : Path, options : SetInputFilesOptions?)
      set_input_files(selector, [file], options)
    end

    def set_input_files(selector : String, files : Array(Path))
      set_input_files(selector, files, nil)
    end

    abstract def set_input_files(selector : String, file : Array(Path), options : SetInputFilesOptions?)

    def set_input_files(selector : String, file : FileChooser::FilePayload)
      set_input_files(selector, file, nil)
    end

    def set_input_files(selector : String, file : FileChooser::FilePayload, options : SetInputFilesOptions?)
      set_input_files(selector, [file], options)
    end

    def set_input_files(selector : String, files : Array(FileChooser::FilePayload))
      set_input_files(selector, files, nil)
    end

    # This method expects `selector` to point to an input element.
    # Sets the value of the file input to these file paths or files. If some of the `filePaths` are relative paths, then they are resolved relative to the the current working directory. For empty array, clears the selected files.
    abstract def set_input_files(selector : String, file : Array(FileChooser::FilePayload), options : SetInputFilesOptions?)
    # In the case of multiple pages in a single browser, each page can have its own viewport size. However, `browser.newContext([options])` allows to set viewport size (and more) for all pages in the context at once.
    # `page.setViewportSize` will resize the page. A lot of websites don't expect phones to change size, so you should set the viewport size before navigating to the page.
    #
    abstract def set_viewport_size(width : Int32, height : Int32)

    def tap(selector : String) : Nil
      tap(selector, nil)
    end

    # This method taps an element matching `selector` by performing the following steps:
    #
    # Find an element match matching `selector`. If there is none, wait until a matching element is attached to the DOM.
    # Wait for actionability checks on the matched element, unless `force` option is set. If the element is detached during the checks, the whole action is retried.
    # Scroll the element into view if needed.
    # Use page.touchscreen to tap the center of the element, or the specified `position`.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    #
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    #
    # **NOTE** `page.tap()` requires that the `hasTouch` option of the browser context be set to true.
    #
    # Shortcut for main frame's `frame.tap(selector[, options])`.
    abstract def tap(selector : String, options : TapOptions?) : Nil

    def text_content(selector : String) : String?
      text_content(selector, nil)
    end

    # Returns `element.textContent`.
    abstract def text_content(selector : String, options : TextContentOptions?) : String?
    # Returns the page's title. Shortcut for main frame's `frame.title()`.
    abstract def title : String

    def type(selector : String, text : String) : Nil
      type(selector, text, nil)
    end

    # Sends a `keydown`, `keypress`/`input`, and `keyup` event for each character in the text. `page.type` can be used to send fine-grained keyboard events. To fill values in form fields, use `page.fill(selector, value[, options])`.
    # To press a special key, like `Control` or `ArrowDown`, use `keyboard.press(key[, options])`.
    #
    # Shortcut for main frame's `frame.type(selector, text[, options])`.
    abstract def type(selector : String, text : String, options : TypeOptions?) : Nil

    def uncheck(selector : String) : Nil
      uncheck(selector, nil)
    end

    # This method unchecks an element matching `selector` by performing the following steps:
    #
    # Find an element match matching `selector`. If there is none, wait until a matching element is attached to the DOM.
    # Ensure that matched element is a checkbox or a radio input. If not, this method rejects. If the element is already unchecked, this method returns immediately.
    # Wait for actionability checks on the matched element, unless `force` option is set. If the element is detached during the checks, the whole action is retried.
    # Scroll the element into view if needed.
    # Use page.mouse to click in the center of the element.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    # Ensure that the element is now unchecked. If not, this method rejects.
    #
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    # Shortcut for main frame's `frame.uncheck(selector[, options])`.
    abstract def uncheck(selector : String, options : UncheckOptions?) : Nil

    def unroute(url : String)
      unroute(url, nil)
    end

    def unroute(url : Regex)
      unroute(url, nil)
    end

    def unroute(url : (String) -> Bool)
      unroute(url, nil)
    end

    abstract def unroute(url : String, handler : Consumer(Route)?)
    abstract def unroute(url : Regex, handler : Consumer(Route)?)
    # Removes a route created with `page.route(url, handler)`. When `handler` is not specified, removes all routes for the `url`.
    abstract def unroute(url : (String) -> Bool, handler : Consumer(Route)?)
    # Shortcut for main frame's `frame.url()`.
    abstract def url : String
    # Video object associated with this page.
    abstract def video : Video?
    abstract def viewport_size : ViewPort?

    def wait_for_event(event : EventType) : Deferred(Event(EventType))
      wait_for_event(event, nil)
    end

    def wait_for_event(event : EventType, predicate : ((Event(EventType)) -> Bool)) : Deferred(Event(EventType))
      options = WaitForEventOptions.new
      options.predicate = predicate
      wait_for_event(event, options)
    end

    # Returns the event data value.
    # Waits for event to fire and passes its value into the predicate function. Returns when the predicate returns truthy value. Will throw an error if the page is closed before the event is fired.
    abstract def wait_for_event(event : EventType, options : WaitForEventOptions?) : Deferred(Event(EventType))

    def wait_for_function(page_function : String, arg : Array(Any)?) : Deferred(JSHandle)
      wait_for_function(page_function, arg, nil)
    end

    def wait_for_function(page_function : String) : Deferred(JSHandle)
      wait_for_function(page_function, nil)
    end

    def wait_for_function(page_function : String, *arg : Any) : Deferred(JSHandle)
      wait_for_function(page_function, arg.to_a)
    end

    # Returns when the `pageFunction` returns a truthy value. It resolves to a JSHandle of the truthy value.
    # The `waitForFunction` can be used to observe viewport size change:
    #
    # To pass an argument to the predicate of `page.waitForFunction` function:
    #
    # Shortcut for main frame's `frame.waitForFunction(pageFunction[, arg, options])`.
    abstract def wait_for_function(page_function : String, arg : Array(Any)?, options : WaitForFunctionOptions?) : Deferred(JSHandle)

    def wait_for_load_state(state : LoadState?) : Deferred(Nil)
      wait_for_load_state(state, nil)
    end

    def wait_for_load_state : Deferred(Nil)
      wait_for_load_state(nil)
    end

    # Returns when the required load state has been reached.
    # This resolves when the page reaches a required load state, `load` by default. The navigation must have been committed when this method is called. If current document has already reached the required state, resolves immediately.
    #
    #
    # Shortcut for main frame's `frame.waitForLoadState([state, options])`.
    abstract def wait_for_load_state(state : LoadState?, options : WaitForLoadStateOptions?) : Deferred(Nil)

    def wait_for_navigation : Deferred(Response?)
      wait_for_navigation(nil)
    end

    # Returns the main resource response. In case of multiple redirects, the navigation will resolve with the response of the last redirect. In case of navigation to a different anchor or navigation due to History API usage, the navigation will resolve with `null`.
    # This resolves when the page navigates to a new URL or reloads. It is useful for when you run code which will indirectly cause the page to navigate. e.g. The click target has an `onclick` handler that triggers navigation from a `setTimeout`. Consider this example:
    #
    # **NOTE** Usage of the History API to change the URL is considered a navigation.
    # Shortcut for main frame's `frame.waitForNavigation([options])`.
    abstract def wait_for_navigation(options : WaitForNavigationOptions?) : Deferred(Response?)

    def wait_for_request(url_glob : String) : Deferred(Request?)
      wait_for_request(url_glob, nil)
    end

    def wait_for_request(url_pattern : Regex) : Deferred(Request?)
      wait_for_request(url_pattern, nil)
    end

    def wait_for_request(predicate : (String -> Bool)?) : Deferred(Request?)
      wait_for_request(predicate, nil)
    end

    abstract def wait_for_request(url_glob : String, options : WaitForRequestOptions?) : Deferred(Request?)

    abstract def wait_for_request(url_pattern : Regex, options : WaitForRequestOptions?) : Deferred(Request?)

    abstract def wait_for_request(predicate : (String -> Bool)?, options : WaitForRequestOptions?) : Deferred(Request?)

    def wait_for_response(url_glob : String) : Deferred(Response?)
      wait_for_response(url_glob, nil)
    end

    def wait_for_response(url_pattern : Regex) : Deferred(Response?)
      wait_for_response(url_pattern, nil)
    end

    def wait_for_response(predicate : (String -> Bool)?) : Deferred(Response?)
      wait_for_response(predicate, nil)
    end

    abstract def wait_for_response(url_glob : String, options : WaitForResponseOptions?) : Deferred(Response?)

    abstract def wait_for_response(url_pattern : Regex, options : WaitForResponseOptions?) : Deferred(Response?)

    abstract def wait_for_response(predicate : (String -> Bool)?, options : WaitForResponseOptions?) : Deferred(Response?)

    def wait_for_selector(selector : String) : Deferred(ElementHandle?)
      wait_for_selector(selector, nil)
    end

    # Returns when element specified by selector satisfies `state` option. Returns `null` if waiting for `hidden` or `detached`.
    # Wait for the `selector` to satisfy `state` option (either appear/disappear from dom, or become visible/hidden). If at the moment of calling the method `selector` already satisfies the condition, the method will return immediately. If the selector doesn't satisfy the condition for the `timeout` milliseconds, the function will throw.
    # This method works across navigations:
    #
    abstract def wait_for_selector(selector : String, options : WaitForSelectorOptions?) : Deferred(ElementHandle?)
    # Waits for the given `timeout` in milliseconds.
    # Note that `page.waitForTimeout()` should only be used for debugging. Tests using the timer in production are going to be flaky. Use signals such as network events, selectors becoming visible and others instead.
    #
    # Shortcut for main frame's `frame.waitForTimeout(timeout)`.
    abstract def wait_for_timeout(timeout : Int32) : Deferred(Nil)
    # This method returns all of the dedicated WebWorkers associated with the page.
    #
    # **NOTE** This does not contain ServiceWorkers
    abstract def workers : Array(Worker)
    abstract def accessibility : Accessibility
    abstract def keyboard : Keyboard
    abstract def mouse : Mouse
    abstract def touchscreen : Touchscreen
  end
end
