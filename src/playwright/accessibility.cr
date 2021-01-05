require "json"

module Playwright
  # The Accessibility class provides methods for inspecting Chromium's accessibility tree. The accessibility tree is used by assistive technology such as screen readers or switches.
  # Accessibility is a very platform-specific thing. On different platforms, there are different screen readers that might have wildly different output.
  # Blink - Chromium's rendering engine - has a concept of "accessibility tree", which is then translated into different platform-specific APIs. Accessibility namespace gives users access to the Blink Accessibility Tree.
  # Most of the accessibility tree gets filtered out when converting from Blink AX Tree to Platform-specific AX-Tree or by assistive technologies themselves. By default, Playwright tries to approximate this filtering, exposing only the "interesting" nodes of the tree.
  module Accessibility
    class SnapshotOptions
      include JSON::Serializable
      # Prune uninteresting nodes from the tree. Defaults to `true`.
      @[JSON::Field(key: "interestingOnly")]
      property interesting_only : Bool?
      # The root DOM element for the snapshot. Defaults to the whole page.
      @[JSON::Field(key: "root")]
      property root : ElementHandle?

      def initialize(@interesting_only = nil, @root = nil)
      end
    end

    def snapshot : AccessibilityNode?
      snapshot(nil)
    end

    # Captures the current state of the accessibility tree. The returned object represents the root accessible node of the page.
    #
    # **NOTE** The Chromium accessibility tree contains nodes that go unused on most platforms and by most screen readers. Playwright will discard them as well for an easier to process tree, unless `interestingOnly` is set to `false`.
    #
    # An example of dumping the entire accessibility tree:
    #
    # An example of logging the focused node's name:
    #
    abstract def snapshot(options : SnapshotOptions?) : AccessibilityNode?
  end
end
