require "path"
require "regex"
require "json"

module Playwright
  # At every point of time, page exposes its current frame tree via the `page.mainFrame()` and `frame.childFrames()` methods.
  # Frame object's lifecycle is controlled by three events, dispatched on the page object:
  #
  # page.on('frameattached') - fired when the frame gets attached to the page. A Frame can be attached to the page only once.
  # page.on('framenavigated') - fired when the frame commits navigation to a different URL.
  # page.on('framedetached') - fired when the frame gets detached from the page.  A Frame can be detached from the page only once.
  #
  # An example of dumping frame tree:
  #
  # An example of getting text from an iframe element:
  #
  module Frame
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
      property wait_until : LoadState?
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
      property wait_until : LoadState?

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
      # URL string, URL regex pattern or predicate receiving URL to match while waiting for the navigation.

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
      property wait_until : LoadState?

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

    # Returns the ElementHandle pointing to the frame element.
    # The method finds an element matching the specified selector within the frame. See Working with selectors for more details. If no elements match the selector, returns `null`.
    abstract def query_selector(selector : String) : ElementHandle?
    # Returns the ElementHandles pointing to the frame elements.
    # The method finds all elements matching the specified selector within the frame. See Working with selectors for more details. If no elements match the selector, returns empty array.
    abstract def query_selector_all(selector : String) : Array(ElementHandle)

    def eval_on_selector(selector : String, page_function : String) : Any
      eval_on_selector(selector, page_function, nil)
    end

    def eval_on_selector(selector : String, page_function : String, *arg : Any) : Any
      eval_on_selector(selector, page_function, arg.to_a)
    end

    # Returns the return value of `pageFunction`
    # The method finds an element matching the specified selector within the frame and passes it as a first argument to `pageFunction`. See Working with selectors for more details. If no elements match the selector, the method throws an error.
    # If `pageFunction` returns a Promise, then `frame.$eval` would wait for the promise to resolve and return its value.
    # Examples:
    #
    abstract def eval_on_selector(selector : String, page_function : String, arg : Array(Any)?) : Any

    def eval_on_selector_all(selector : String, page_function : String) : Any
      eval_on_selector_all(selector, page_function, nil)
    end

    def eval_on_selector_all(selector : String, page_function : String, *arg : Any) : Any
      eval_on_selector_all(selector, page_function, arg.to_a)
    end

    # Returns the return value of `pageFunction`
    # The method finds all elements matching the specified selector within the frame and passes an array of matched elements as a first argument to `pageFunction`. See Working with selectors for more details.
    # If `pageFunction` returns a Promise, then `frame.$$eval` would wait for the promise to resolve and return its value.
    # Examples:
    #
    abstract def eval_on_selector_all(selector : String, page_function : String, arg : Array(Any)?) : Any
    # Returns the added tag when the script's onload fires or when the script content was injected into frame.
    # Adds a `<script>` tag into the page with the desired url or content.
    abstract def add_script_tag(params : AddScriptTagParams) : ElementHandle
    # Returns the added tag when the stylesheet's onload fires or when the CSS content was injected into frame.
    # Adds a `<link rel="stylesheet">` tag into the page with the desired url or a `<style type="text/css">` tag with the content.
    abstract def add_style_tag(params : AddStyleTagParams) : ElementHandle

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
    abstract def check(selector : String, options : CheckOptions?) : Nil
    abstract def child_frames : Array(Frame)

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
    abstract def click(selector : String, options : ClickOptions?) : Nil
    # Gets the full HTML contents of the frame, including the doctype.
    abstract def content : String

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
    # **NOTE** `frame.dblclick()` dispatches two `click` events and a single `dblclick` event.
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

    def evaluate(page_function : String) : Any
      evaluate(page_function, nil)
    end

    def evaluate(page_function : String, *arg : Any) : Any
      evaluate(page_function, arg.to_a)
    end

    # Returns the return value of `pageFunction`
    # If the function passed to the `frame.evaluate` returns a Promise, then `frame.evaluate` would wait for the promise to resolve and return its value.
    # If the function passed to the `frame.evaluate` returns a non-Serializable value, then `frame.evaluate` returns `undefined`. DevTools Protocol also supports transferring some additional values that are not serializable by `JSON`: `-0`, `NaN`, `Infinity`, `-Infinity`, and bigint literals.
    #
    # A string can also be passed in instead of a function.
    #
    # ElementHandle instances can be passed as an argument to the `frame.evaluate`:
    #
    abstract def evaluate(page_function : String, arg : Array(Any)?) : Any

    def evaluate_handle(page_function : String) : JSHandle
      evaluate_handle(page_function, nil)
    end

    def evaluate_handle(page_function : String, *arg : Any) : JSHandle
      evaluate_handle(page_function, arg.to_a)
    end

    # Returns the return value of `pageFunction` as in-page object (JSHandle).
    # The only difference between `frame.evaluate` and `frame.evaluateHandle` is that `frame.evaluateHandle` returns in-page object (JSHandle).
    # If the function, passed to the `frame.evaluateHandle`, returns a Promise, then `frame.evaluateHandle` would wait for the promise to resolve and return its value.
    #
    # A string can also be passed in instead of a function.
    #
    # JSHandle instances can be passed as an argument to the `frame.evaluateHandle`:
    #
    abstract def evaluate_handle(page_function : String, arg : Array(Any)?) : JSHandle

    def fill(selector : String, value : String) : Nil
      fill(selector, value, nil)
    end

    # This method waits for an element matching `selector`, waits for actionability checks, focuses the element, fills it and triggers an `input` event after filling. If the element matching `selector` is not an `<input>`, `<textarea>` or `[contenteditable]` element, this method throws an error. Note that you can pass an empty string to clear the input field.
    # To send fine-grained keyboard events, use `frame.type(selector, text[, options])`.
    abstract def fill(selector : String, value : String, options : FillOptions?) : Nil

    def focus(selector : String) : Nil
      focus(selector, nil)
    end

    # This method fetches an element with `selector` and focuses it. If there's no element matching `selector`, the method waits until a matching element appears in the DOM.
    abstract def focus(selector : String, options : FocusOptions?) : Nil
    # Returns the `frame` or `iframe` element handle which corresponds to this frame.
    # This is an inverse of `elementHandle.contentFrame()`. Note that returned handle actually belongs to the parent frame.
    # This method throws an error if the frame has been detached before `frameElement()` returns.
    #
    abstract def frame_element : ElementHandle

    def get_attribute(selector : String, name : String) : String?
      get_attribute(selector, name, nil)
    end

    # Returns element attribute value.
    abstract def get_attribute(selector : String, name : String, options : GetAttributeOptions?) : String?

    def goto(url : String) : Response?
      goto(url, nil)
    end

    # Returns the main resource response. In case of multiple redirects, the navigation will resolve with the response of the last redirect.
    # `frame.goto` will throw an error if:
    #
    # there's an SSL error (e.g. in case of self-signed certificates).
    # target URL is invalid.
    # the `timeout` is exceeded during navigation.
    # the remote server does not respond or is unreachable.
    # the main resource failed to load.
    #
    # `frame.goto` will not throw an error when any valid HTTP status code is returned by the remote server, including 404 "Not Found" and 500 "Internal Server Error".  The status code for such responses can be retrieved by calling `response.status()`.
    #
    # **NOTE** `frame.goto` either throws an error or returns a main resource response. The only exceptions are navigation to `about:blank` or navigation to the same URL with a different hash, which would succeed and return `null`.
    # **NOTE** Headless mode doesn't support navigation to a PDF document. See the upstream issue.
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
    # Returns `true` if the frame has been detached, or `false` otherwise.
    abstract def is_detached : Bool
    # Returns frame's name attribute as specified in the tag.
    # If the name is empty, returns the id attribute instead.
    #
    # **NOTE** This value is calculated once when the frame is created, and will not update if the attribute is changed later.
    abstract def name : String
    # Returns the page containing this frame.
    abstract def page : Page?
    # Parent frame, if any. Detached frames and main frames return `null`.
    abstract def parent_frame : Frame?

    def press(selector : String, key : String) : Nil
      press(selector, key, nil)
    end

    # `key` can specify the intended keyboardEvent.key value or a single character to generate the text for. A superset of the `key` values can be found here. Examples of the keys are:
    # `F1` - `F12`, `Digit0`- `Digit9`, `KeyA`- `KeyZ`, `Backquote`, `Minus`, `Equal`, `Backslash`, `Backspace`, `Tab`, `Delete`, `Escape`, `ArrowDown`, `End`, `Enter`, `Home`, `Insert`, `PageDown`, `PageUp`, `ArrowRight`, `ArrowUp`, etc.
    # Following modification shortcuts are also suported: `Shift`, `Control`, `Alt`, `Meta`, `ShiftLeft`.
    # Holding down `Shift` will type the text that corresponds to the `key` in the upper case.
    # If `key` is a single character, it is case-sensitive, so the values `a` and `A` will generate different respective texts.
    # Shortcuts such as `key: "Control+o"` or `key: "Control+Shift+T"` are supported as well. When speficied with the modifier, modifier is pressed and being held while the subsequent key is being pressed.
    abstract def press(selector : String, key : String, options : PressOptions?) : Nil

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

    abstract def select_option(selector : String, values : Array(ElementHandle)?, options : SelectOptionOptions?)

    def set_content(html : String) : Nil
      set_content(html, nil)
    end

    abstract def set_content(html : String, options : SetContentOptions?) : Nil

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
    # **NOTE** `frame.tap()` requires that the `hasTouch` option of the browser context be set to true.
    abstract def tap(selector : String, options : TapOptions?) : Nil

    def text_content(selector : String) : String?
      text_content(selector, nil)
    end

    # Returns `element.textContent`.
    abstract def text_content(selector : String, options : TextContentOptions?) : String?
    # Returns the page title.
    abstract def title : String

    def type(selector : String, text : String) : Nil
      type(selector, text, nil)
    end

    # Sends a `keydown`, `keypress`/`input`, and `keyup` event for each character in the text. `frame.type` can be used to send fine-grained keyboard events. To fill values in form fields, use `frame.fill(selector, value[, options])`.
    # To press a special key, like `Control` or `ArrowDown`, use `keyboard.press(key[, options])`.
    #
    abstract def type(selector : String, text : String, options : TypeOptions?) : Nil

    def uncheck(selector : String) : Nil
      uncheck(selector, nil)
    end

    # This method checks an element matching `selector` by performing the following steps:
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
    abstract def uncheck(selector : String, options : UncheckOptions?) : Nil
    # Returns frame's url.
    abstract def url : String

    def wait_for_function(page_function : String, arg : Array(Any)?) : Deferred(JSHandle)
      wait_for_function(page_function, arg, nil)
    end

    def wait_for_function(page_function : String) : Deferred(JSHandle)
      wait_for_function(page_function, nil)
    end

    def wait_for_function(page_function : String, *arg : Any) : Deferred(JSHandle)
      wait_for_function(page_function, arg.to_a)
    end

    # Returns when the `pageFunction` returns a truthy value, returns that value.
    # The `waitForFunction` can be used to observe viewport size change:
    #
    # To pass an argument to the predicate of `frame.waitForFunction` function:
    #
    abstract def wait_for_function(page_function : String, arg : Array(Any)?, options : WaitForFunctionOptions?) : Deferred(JSHandle)

    def wait_for_load_state(state : LoadState?) : Deferred(Nil)
      wait_for_load_state(state, nil)
    end

    def wait_for_load_state : Deferred(Nil)
      wait_for_load_state(nil)
    end

    # Waits for the required load state to be reached.
    # This returns when the frame reaches a required load state, `load` by default. The navigation must have been committed when this method is called. If current document has already reached the required state, resolves immediately.
    #
    abstract def wait_for_load_state(state : LoadState?, options : WaitForLoadStateOptions?) : Deferred(Nil)

    def wait_for_navigation : Deferred(Response?)
      wait_for_navigation(nil)
    end

    # Returns the main resource response. In case of multiple redirects, the navigation will resolve with the response of the last redirect. In case of navigation to a different anchor or navigation due to History API usage, the navigation will resolve with `null`.
    # This method waits for the frame to navigate to a new URL. It is useful for when you run code which will indirectly cause the frame to navigate. Consider this example:
    #
    # **NOTE** Usage of the History API to change the URL is considered a navigation.
    abstract def wait_for_navigation(options : WaitForNavigationOptions?) : Deferred(Response?)

    def wait_for_selector(selector : String) : Deferred(ElementHandle?)
      wait_for_selector(selector, nil)
    end

    # Returns when element specified by selector satisfies `state` option. Returns `null` if waiting for `hidden` or `detached`.
    # Wait for the `selector` to satisfy `state` option (either appear/disappear from dom, or become visible/hidden). If at the moment of calling the method `selector` already satisfies the condition, the method will return immediately. If the selector doesn't satisfy the condition for the `timeout` milliseconds, the function will throw.
    # This method works across navigations:
    #
    abstract def wait_for_selector(selector : String, options : WaitForSelectorOptions?) : Deferred(ElementHandle?)
    # Waits for the given `timeout` in milliseconds.
    # Note that `frame.waitForTimeout()` should only be used for debugging. Tests using the timer in production are going to be flaky. Use signals such as network events, selectors becoming visible and others instead.
    abstract def wait_for_timeout(timeout : Int32) : Deferred(Nil)
  end
end
