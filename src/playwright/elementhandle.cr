require "path"
require "./jshandle"
require "json"

module Playwright
  # ElementHandle represents an in-page DOM element. ElementHandles can be created with the `page.$(selector)` method.
  #
  # ElementHandle prevents DOM element from garbage collection unless the handle is disposed with `jsHandle.dispose()`. ElementHandles are auto-disposed when their origin frame gets navigated.
  # ElementHandle instances can be used as an argument in `page.$eval(selector, pageFunction[, arg])` and `page.evaluate(pageFunction[, arg])` methods.
  module ElementHandle
    include JSHandle

    class BoundingBox
      include JSON::Serializable
      property x : Float64?
      property y : Float64?
      property width : Float64?
      property height : Float64?

      def initialize(@x = nil, @y = nil, @width = nil, @height = nil)
      end
    end

    class SelectOption
      include JSON::Serializable
      property value : String?
      property label : String?
      property index : Int32?

      def initialize(@value = nil, @label = nil, @index = nil)
      end
    end

    enum ElementState
      DISABLED
      ENABLED
      HIDDEN
      STABLE
      VISIBLE

      def to_s
        super.downcase
      end

      def to_json(json : JSON::Builder)
        json.string(to_s)
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
      # The file path to save the image to. The screenshot type will be inferred from file extension. If `path` is a relative path, then it is resolved relative to the current working directory. If no path is provided, the image won't be saved to the disk.
      @[JSON::Field(key: "path")]
      property path : Path?
      # Specify screenshot type, defaults to `png`.
      @[JSON::Field(key: "type")]
      property type : Type?
      # The quality of the image, between 0-100. Not applicable to `png` images.
      @[JSON::Field(key: "quality")]
      property quality : Int32?
      # Hides default white background and allows capturing screenshots with transparency. Not applicable to `jpeg` images. Defaults to `false`.
      @[JSON::Field(key: "omitBackground")]
      property omit_background : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@path = nil, @type = nil, @quality = nil, @omit_background = nil, @timeout = nil)
      end
    end

    class ScrollIntoViewIfNeededOptions
      include JSON::Serializable
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
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

    class SelectTextOptions
      include JSON::Serializable
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@timeout = nil)
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
      # Whether to bypass the actionability checks. Defaults to `false`.
      @[JSON::Field(key: "force")]
      property force : Bool?
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@position = nil, @modifiers = nil, @force = nil, @no_wait_after = nil, @timeout = nil)
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

    class WaitForElementStateOptions
      include JSON::Serializable
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
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

    # The method finds an element matching the specified selector in the `ElementHandle`'s subtree. See Working with selectors for more details. If no elements match the selector, returns `null`.
    abstract def query_selector(selector : String) : ElementHandle?
    # The method finds all elements matching the specified selector in the `ElementHandle`s subtree. See Working with selectors for more details. If no elements match the selector, returns empty array.
    abstract def query_selector_all(selector : String) : Array(ElementHandle)

    def eval_on_selector(selector : String, page_function : String) : Any
      eval_on_selector(selector, page_function, nil)
    end

    def eval_on_selector(selector : String, page_function : String, *arg : Any) : Any
      eval_on_selector(selector, page_function, arg.to_a)
    end

    # Returns the return value of `pageFunction`
    # The method finds an element matching the specified selector in the `ElementHandle`s subtree and passes it as a first argument to `pageFunction`. See Working with selectors for more details. If no elements match the selector, the method throws an error.
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
    # The method finds all elements matching the specified selector in the `ElementHandle`'s subtree and passes an array of matched elements as a first argument to `pageFunction`. See Working with selectors for more details.
    # If `pageFunction` returns a Promise, then `frame.$$eval` would wait for the promise to resolve and return its value.
    # Examples:
    #
    #
    abstract def eval_on_selector_all(selector : String, page_function : String, arg : Array(Any)?) : Any
    # This method returns the bounding box of the element, or `null` if the element is not visible. The bounding box is calculated relative to the main frame viewport - which is usually the same as the browser window.
    # Scrolling affects the returned bonding box, similarly to Element.getBoundingClientRect. That means `x` and/or `y` may be negative.
    # Elements from child frames return the bounding box relative to the main frame, unlike the Element.getBoundingClientRect.
    # Assuming the page is static, it is safe to use bounding box coordinates to perform input. For example, the following snippet should click the center of the element.
    #
    abstract def bounding_box : BoundingBox?

    def check : Nil
      check(nil)
    end

    # This method checks the element by performing the following steps:
    #
    # Ensure that element is a checkbox or a radio input. If not, this method rejects. If the element is already checked, this method returns immediately.
    # Wait for actionability checks on the element, unless `force` option is set.
    # Scroll the element into view if needed.
    # Use page.mouse to click in the center of the element.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    # Ensure that the element is now checked. If not, this method rejects.
    #
    # If the element is detached from the DOM at any moment during the action, this method rejects.
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    abstract def check(options : CheckOptions?) : Nil

    def click : Nil
      click(nil)
    end

    # This method clicks the element by performing the following steps:
    #
    # Wait for actionability checks on the element, unless `force` option is set.
    # Scroll the element into view if needed.
    # Use page.mouse to click in the center of the element, or the specified `position`.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    #
    # If the element is detached from the DOM at any moment during the action, this method rejects.
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    abstract def click(options : ClickOptions?) : Nil
    # Returns the content frame for element handles referencing iframe nodes, or `null` otherwise
    abstract def content_frame : Frame?

    def dblclick : Nil
      dblclick(nil)
    end

    # This method double clicks the element by performing the following steps:
    #
    # Wait for actionability checks on the element, unless `force` option is set.
    # Scroll the element into view if needed.
    # Use page.mouse to double click in the center of the element, or the specified `position`.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set. Note that if the first click of the `dblclick()` triggers a navigation event, this method will reject.
    #
    # If the element is detached from the DOM at any moment during the action, this method rejects.
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    #
    # **NOTE** `elementHandle.dblclick()` dispatches two `click` events and a single `dblclick` event.
    abstract def dblclick(options : DblclickOptions?) : Nil

    def dispatch_event(type : String) : Nil
      dispatch_event(type, nil)
    end

    def dispatch_event(type : String, *event_init : Any) : Nil
      dispatch_event(type, event_init.to_a)
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
    abstract def dispatch_event(type : String, event_init : Array(Any)?) : Nil

    def fill(value : String) : Nil
      fill(value, nil)
    end

    # This method waits for actionability checks, focuses the element, fills it and triggers an `input` event after filling. If the element is not an `<input>`, `<textarea>` or `[contenteditable]` element, this method throws an error. Note that you can pass an empty string to clear the input field.
    abstract def fill(value : String, options : FillOptions?) : Nil
    # Calls focus on the element.
    abstract def focus : Nil
    # Returns element attribute value.
    abstract def get_attribute(name : String) : String?

    def hover : Nil
      hover(nil)
    end

    # This method hovers over the element by performing the following steps:
    #
    # Wait for actionability checks on the element, unless `force` option is set.
    # Scroll the element into view if needed.
    # Use page.mouse to hover over the center of the element, or the specified `position`.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    #
    # If the element is detached from the DOM at any moment during the action, this method rejects.
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    abstract def hover(options : HoverOptions?) : Nil
    # Returns the `element.innerHTML`.
    abstract def inner_html : String
    # Returns the `element.innerText`.
    abstract def inner_text : String
    # Returns the frame containing the given element.
    abstract def owner_frame : Frame?

    def press(key : String) : Nil
      press(key, nil)
    end

    # Focuses the element, and then uses `keyboard.down(key)` and `keyboard.up(key)`.
    # `key` can specify the intended keyboardEvent.key value or a single character to generate the text for. A superset of the `key` values can be found here. Examples of the keys are:
    # `F1` - `F12`, `Digit0`- `Digit9`, `KeyA`- `KeyZ`, `Backquote`, `Minus`, `Equal`, `Backslash`, `Backspace`, `Tab`, `Delete`, `Escape`, `ArrowDown`, `End`, `Enter`, `Home`, `Insert`, `PageDown`, `PageUp`, `ArrowRight`, `ArrowUp`, etc.
    # Following modification shortcuts are also suported: `Shift`, `Control`, `Alt`, `Meta`, `ShiftLeft`.
    # Holding down `Shift` will type the text that corresponds to the `key` in the upper case.
    # If `key` is a single character, it is case-sensitive, so the values `a` and `A` will generate different respective texts.
    # Shortcuts such as `key: "Control+o"` or `key: "Control+Shift+T"` are supported as well. When speficied with the modifier, modifier is pressed and being held while the subsequent key is being pressed.
    abstract def press(key : String, options : PressOptions?) : Nil

    def screenshot : Bytes
      screenshot(nil)
    end

    # Returns the buffer with the captured screenshot.
    # This method waits for the actionability checks, then scrolls element into view before taking a screenshot. If the element is detached from DOM, the method throws an error.
    abstract def screenshot(options : ScreenshotOptions?) : Bytes

    def scroll_into_view_if_needed : Nil
      scroll_into_view_if_needed(nil)
    end

    # This method waits for actionability checks, then tries to scroll element into view, unless it is completely visible as defined by IntersectionObserver's `ratio`.
    # Throws when `elementHandle` does not point to an element connected to a Document or a ShadowRoot.
    abstract def scroll_into_view_if_needed(options : ScrollIntoViewIfNeededOptions?) : Nil

    def select_option(value : String)
      select_option(value, nil)
    end

    def select_option(value : String, options : SelectOptionOptions?)
      select_option([value], nil)
    end

    def select_option(values : Array(String))
      select_option(values, nil)
    end

    def select_option(values : Array(String), options : SelectOptionOptions?)
      if values.size == 0
        return select_option(SelectOption.new, options)
      end
      select_option(values.map { |v| SelectOption.new(v) }.to_a, options)
    end

    def select_option(value : SelectOption?)
      select_option(value, nil)
    end

    def select_option(value : SelectOption?, options : SelectOptionOptions?)
      select_option(value.nil? ? nil : [value], options)
    end

    def select_option(values : Array(SelectOption)?)
      select_option(values, nil)
    end

    abstract def select_option(values : Array(SelectOption)?, options : SelectOptionOptions?)

    def select_option(value : ElementHandle?)
      select_option(value, nil)
    end

    def select_option(value : ElementHandle?, options : SelectOptionOptions?)
      select_option(value.nil? ? nil : [value], options)
    end

    def select_option(values : Array(ElementHandle)?)
      select_option(values, nil)
    end

    # Returns the array of option values that have been successfully selected.
    # Triggers a `change` and `input` event once all the provided options have been selected. If element is not a `<select>` element, the method throws an error.
    #

    abstract def select_option(values : Array(ElementHandle)?, options : SelectOptionOptions?)

    def select_text : Nil
      select_text(nil)
    end

    # This method waits for actionability checks, then focuses the element and selects all its text content.
    abstract def select_text(options : SelectTextOptions?) : Nil

    def set_input_files(file : Path)
      set_input_files(file, nil)
    end

    def set_input_files(file : Path, options : SetInputFilesOptions?)
      set_input_files([file], options)
    end

    def set_input_files(files : Array(Path))
      set_input_files(files, nil)
    end

    abstract def set_input_files(file : Array(Path), options : SetInputFilesOptions?)

    def set_input_files(file : FileChooser::FilePayload)
      set_input_files(file, nil)
    end

    def set_input_files(file : FileChooser::FilePayload, options : SetInputFilesOptions?)
      set_input_files([file], options)
    end

    def set_input_files(files : Array(FileChooser::FilePayload))
      set_input_files(files, nil)
    end

    # This method expects `elementHandle` to point to an input element.
    # Sets the value of the file input to these file paths or files. If some of the `filePaths` are relative paths, then they are resolved relative to the the current working directory. For empty array, clears the selected files.
    abstract def set_input_files(file : Array(FileChooser::FilePayload), options : SetInputFilesOptions?)

    def tap : Nil
      tap(nil)
    end

    # This method taps the element by performing the following steps:
    #
    # Wait for actionability checks on the element, unless `force` option is set.
    # Scroll the element into view if needed.
    # Use page.touchscreen to tap in the center of the element, or the specified `position`.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    #
    # If the element is detached from the DOM at any moment during the action, this method rejects.
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    #
    # **NOTE** `elementHandle.tap()` requires that the `hasTouch` option of the browser context be set to true.
    abstract def tap(options : TapOptions?) : Nil
    # Returns the `node.textContent`.
    abstract def text_content : String?
    abstract def to_string : String

    def type(text : String) : Nil
      type(text, nil)
    end

    # Focuses the element, and then sends a `keydown`, `keypress`/`input`, and `keyup` event for each character in the text.
    # To press a special key, like `Control` or `ArrowDown`, use `elementHandle.press(key[, options])`.
    #
    # An example of typing into a text field and then submitting the form:
    #
    abstract def type(text : String, options : TypeOptions?) : Nil

    def uncheck : Nil
      uncheck(nil)
    end

    # This method checks the element by performing the following steps:
    #
    # Ensure that element is a checkbox or a radio input. If not, this method rejects. If the element is already unchecked, this method returns immediately.
    # Wait for actionability checks on the element, unless `force` option is set.
    # Scroll the element into view if needed.
    # Use page.mouse to click in the center of the element.
    # Wait for initiated navigations to either succeed or fail, unless `noWaitAfter` option is set.
    # Ensure that the element is now unchecked. If not, this method rejects.
    #
    # If the element is detached from the DOM at any moment during the action, this method rejects.
    # When all steps combined have not finished during the specified `timeout`, this method rejects with a TimeoutError. Passing zero timeout disables this.
    abstract def uncheck(options : UncheckOptions?) : Nil

    def wait_for_element_state(state : ElementState) : Deferred(Nil)
      wait_for_element_state(state, nil)
    end

    # Returns the element satisfies the `state`.
    # Depending on the `state` parameter, this method waits for one of the actionability checks to pass. This method throws when the element is detached while waiting, unless waiting for the `"hidden"` state.
    #
    # `"visible"` Wait until the element is visible.
    # `"hidden"` Wait until the element is not visible or not attached. Note that waiting for hidden does not throw when the element detaches.
    # `"stable"` Wait until the element is both visible and stable.
    # `"enabled"` Wait until the element is enabled.
    # `"disabled"` Wait until the element is not enabled.
    #
    # If the element does not satisfy the condition for the `timeout` milliseconds, this method will throw.
    abstract def wait_for_element_state(state : ElementState, options : WaitForElementStateOptions?) : Deferred(Nil)

    def wait_for_selector(selector : String) : Deferred(ElementHandle?)
      wait_for_selector(selector, nil)
    end

    # Returns element specified by selector satisfies `state` option. Returns `null` if waiting for `hidden` or `detached`.
    # Wait for the `selector` relative to the element handle to satisfy `state` option (either appear/disappear from dom, or become visible/hidden). If at the moment of calling the method `selector` already satisfies the condition, the method will return immediately. If the selector doesn't satisfy the condition for the `timeout` milliseconds, the function will throw.
    #
    #
    # **NOTE** This method does not work across navigations, use `page.waitForSelector(selector[, options])` instead.
    abstract def wait_for_selector(selector : String, options : WaitForSelectorOptions?) : Deferred(ElementHandle?)
  end
end
