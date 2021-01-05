module Playwright
  private class TimeoutSettings
    private DEFAULT_TIMEOUT_MS = 30_000
    getter parent : TimeoutSettings?
    property default_timeout : Int32?
    property default_navigation_timeout : Int32?

    def initialize(@parent = nil)
    end

    def timeout(timeout : Int32?)
      return timeout.not_nil! unless timeout.nil?
      return default_timeout.not_nil! unless default_timeout.nil?
      if p = parent
        return p.timeout(timeout)
      end
      DEFAULT_TIMEOUT_MS
    end

    def navigation_timeout(timeout : Int32?)
      return timeout.not_nil! unless timeout.nil?
      return default_navigation_timeout.not_nil! unless default_navigation_timeout.nil?
      if p = parent
        return p.navigation_timeout(timeout)
      end
      DEFAULT_TIMEOUT_MS
    end
  end
end
