require "json"

module Playwright
  # The Touchscreen class operates in main-frame CSS pixels relative to the top-left corner of the viewport. Methods on the touchscreen can only be used in browser contexts that have been intialized with `hasTouch` set to true.
  module Touchscreen
    # Dispatches a `touchstart` and `touchend` event with a single touch at the position (`x`,`y`).
    abstract def tap(x : Int32, y : Int32) : Nil
  end
end
