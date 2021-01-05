module Playwright
  private class Router
    private record RouteInfo, matcher : UrlMatcher, handler : Consumer(Route)?

    def initialize
      @routes = Array(RouteInfo).new
    end

    def add(matcher : UrlMatcher, handler : Consumer(Route)?)
      @routes << RouteInfo.new(matcher, handler)
    end

    def remove(matcher : UrlMatcher, handler : Consumer(Route)?)
      if handler
        @routes = @routes.reject { |r| r.matcher == matcher && r.handler == handler }
      else
        @routes = @routes.reject { |r| r.matcher == matcher }
      end
    end

    def handle(route : Route) : Bool
      @routes.each do |info|
        if info.matcher.test(route.request.url)
          info.handler.try &.call(route)
          return true
        end
      end
      false
    end

    delegate size, to: @routes
  end
end
