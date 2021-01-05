require "json"

module Playwright
  # Keyboard provides an api for managing a virtual keyboard. The high level api is `keyboard.type(text[, options])`, which takes raw characters and generates proper keydown, keypress/input, and keyup events on your page.
  # For finer control, you can use `keyboard.down(key)`, `keyboard.up(key)`, and `keyboard.insertText(text)` to manually fire events as if they were generated from a real keyboard.
  # An example of holding down `Shift` in order to select and delete some text:
  #
  # An example of pressing uppercase `A`
  #
  # An example to trigger select-all with the keyboard
  #
  module Keyboard
    enum Modifier
      ALT
      CONTROL
      META
      SHIFT

      def to_s
        super.capitalize
      end

      def to_json(json : JSON::Builder)
        json.string(to_s)
      end
    end

    # Dispatches a `keydown` event.
    # `key` can specify the intended keyboardEvent.key value or a single character to generate the text for. A superset of the `key` values can be found here. Examples of the keys are:
    # `F1` - `F12`, `Digit0`- `Digit9`, `KeyA`- `KeyZ`, `Backquote`, `Minus`, `Equal`, `Backslash`, `Backspace`, `Tab`, `Delete`, `Escape`, `ArrowDown`, `End`, `Enter`, `Home`, `Insert`, `PageDown`, `PageUp`, `ArrowRight`, `ArrowUp`, etc.
    # Following modification shortcuts are also suported: `Shift`, `Control`, `Alt`, `Meta`, `ShiftLeft`.
    # Holding down `Shift` will type the text that corresponds to the `key` in the upper case.
    # If `key` is a single character, it is case-sensitive, so the values `a` and `A` will generate different respective texts.
    # If `key` is a modifier key, `Shift`, `Meta`, `Control`, or `Alt`, subsequent key presses will be sent with that modifier active. To release the modifier key, use `keyboard.up(key)`.
    # After the key is pressed once, subsequent calls to `keyboard.down(key)` will have repeat set to true. To release the key, use `keyboard.up(key)`.
    #
    # **NOTE** Modifier keys DO influence `keyboard.down`. Holding down `Shift` will type the text in upper case.
    abstract def down(key : String) : Nil
    # Dispatches only `input` event, does not emit the `keydown`, `keyup` or `keypress` events.
    #
    #
    # **NOTE** Modifier keys DO NOT effect `keyboard.insertText`. Holding down `Shift` will not type the text in upper case.
    abstract def insert_text(text : String) : Nil

    def press(key : String) : Nil
      press(key, nil)
    end

    # `key` can specify the intended keyboardEvent.key value or a single character to generate the text for. A superset of the `key` values can be found here. Examples of the keys are:
    # `F1` - `F12`, `Digit0`- `Digit9`, `KeyA`- `KeyZ`, `Backquote`, `Minus`, `Equal`, `Backslash`, `Backspace`, `Tab`, `Delete`, `Escape`, `ArrowDown`, `End`, `Enter`, `Home`, `Insert`, `PageDown`, `PageUp`, `ArrowRight`, `ArrowUp`, etc.
    # Following modification shortcuts are also suported: `Shift`, `Control`, `Alt`, `Meta`, `ShiftLeft`.
    # Holding down `Shift` will type the text that corresponds to the `key` in the upper case.
    # If `key` is a single character, it is case-sensitive, so the values `a` and `A` will generate different respective texts.
    # Shortcuts such as `key: "Control+o"` or `key: "Control+Shift+T"` are supported as well. When speficied with the modifier, modifier is pressed and being held while the subsequent key is being pressed.
    #
    # Shortcut for `keyboard.down(key)` and `keyboard.up(key)`.
    abstract def press(key : String, delay : Int32?) : Nil

    def type(text : String) : Nil
      type(text, nil)
    end

    # Sends a `keydown`, `keypress`/`input`, and `keyup` event for each character in the text.
    # To press a special key, like `Control` or `ArrowDown`, use `keyboard.press(key[, options])`.
    #
    #
    # **NOTE** Modifier keys DO NOT effect `keyboard.type`. Holding down `Shift` will not type the text in upper case.
    abstract def type(text : String, delay : Int32?) : Nil
    # Dispatches a `keyup` event.
    abstract def up(key : String) : Nil
  end
end
