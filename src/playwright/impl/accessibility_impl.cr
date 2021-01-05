require "../accessibility"
require "./accessibility_node"

module Playwright
  private class AccessibilityImpl
    include Accessibility

    def initialize(@page : PageImpl)
    end

    def snapshot(options : SnapshotOptions?) : AccessibilityNode?
      options ||= SnapshotOptions.new
      json = @page.send_message("accessibilitySnapshot", JSON.parse(options.to_json))
      return nil unless json["rootAXNode"]?
      AccessibilityNode.from_json(json["rootAXNode"].to_json)
    end
  end
end
