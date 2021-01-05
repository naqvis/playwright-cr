require "path"
require "regex"
require "json"

module Playwright
  # BrowserContexts provide a way to operate multiple independent browser sessions.
  # If a page opens another page, e.g. with a `window.open` call, the popup will belong to the parent page's browser context.
  # Playwright allows creation of "incognito" browser contexts with `browser.newContext()` method. "Incognito" browser contexts don't write any browsing data to disk.
  #
  module BrowserContext
    enum SameSite
      STRICT
      LAX
      NONE

      def to_s
        super.capitalize
      end

      def to_json(json : JSON::Builder)
        json.string(to_s)
      end
    end

    class HTTPCredentials
      include JSON::Serializable
      getter username : String
      getter password : String

      def initialize(@username, @password)
      end
    end

    class StorageState
      include JSON::Serializable
      property cookies : Array(AddCookie)
      property origins : Array(OriginState)

      class OriginState
        include JSON::Serializable
        getter origin : String
        @[JSON::Field(key: "localStorage")]
        property local_storage : Array(LocalStorageItem)

        class LocalStorageItem
          include JSON::Serializable
          getter name : String
          getter value : String

          def initialize(@name, @value)
          end
        end

        def initialize(@origin, @local_storage = Array(LocalStorageItem).new)
        end
      end

      def initialize
        @cookies = Array(AddCookie).new
        @origins = Array(OriginState).new
      end
    end

    class WaitForEventOptions
      property timeout : Int32?
      property predicate : ((Event(EventType)) -> Bool) | Nil

      def initialize(@timeout = nil, @predicate = nil)
      end
    end

    enum EventType
      CLOSE
      PAGE
    end

    abstract def add_listener(type : EventType, listener : Listener(EventType))
    abstract def remove_listener(type : EventType, listener : Listener(EventType))

    class AddCookie
      include JSON::Serializable
      # **required**
      @[JSON::Field(key: "name")]
      property name : String
      # **required**
      @[JSON::Field(key: "value")]
      property value : String
      # either url or domain / path are required
      @[JSON::Field(key: "url")]
      property url : String?
      # either url or domain / path are required
      @[JSON::Field(key: "domain")]
      property domain : String?
      # either url or domain / path are required
      @[JSON::Field(key: "path")]
      property path : String?
      # Unix time in seconds.
      @[JSON::Field(key: "expires")]
      property expires : Int64?
      @[JSON::Field(key: "httpOnly")]
      property http_only : Bool?
      @[JSON::Field(key: "secure")]
      property secure : Bool?
      @[JSON::Field(key: "sameSite")]
      property same_site : SameSite?

      def initialize(@name, @value, @url = nil, @domain = nil, @path = nil, @expires = nil, @http_only = nil, @secure = nil, @same_site = nil)
      end
    end

    class Cookie
      include JSON::Serializable
      @[JSON::Field(key: "name")]
      getter name : String
      @[JSON::Field(key: "value")]
      getter value : String
      @[JSON::Field(key: "domain")]
      getter domain : String
      @[JSON::Field(key: "path")]
      getter path : String
      # Unix time in seconds.
      @[JSON::Field(key: "expires")]
      getter expires : Int64
      @[JSON::Field(key: "httpOnly")]
      getter http_only : Bool
      @[JSON::Field(key: "secure")]
      getter secure : Bool
      @[JSON::Field(key: "sameSite")]
      getter same_site : SameSite

      def initialize(@name, @value, @domain, @path, @expires, @http_only, @secure, @same_site)
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

    class GrantPermissionsOptions
      include JSON::Serializable
      # The origin to grant permissions to, e.g. "https://example.com".
      @[JSON::Field(key: "origin")]
      property origin : String?

      def initialize(@origin = nil)
      end
    end

    class StorageStateOptions
      include JSON::Serializable
      # The file path to save the storage state to. If `path` is a relative path, then it is resolved relative to current working directory. If no path is provided, storage state is still returned, but won't be saved to the disk.
      @[JSON::Field(key: "path")]
      property path : Path?

      def initialize(@path = nil)
      end
    end

    # Adds cookies into this browser context. All pages within this context will have these cookies installed. Cookies can be obtained via `browserContext.cookies([urls])`.
    #
    abstract def add_cookies(cookies : Array(AddCookie))

    def add_init_script(script : String) : Nil
      add_init_script(script, nil)
    end

    # Adds a script which would be evaluated in one of the following scenarios:
    #
    # Whenever a page is created in the browser context or is navigated.
    # Whenever a child frame is attached or navigated in any page in the browser context. In this case, the script is evaluated in the context of the newly attached frame.
    #
    # The script is evaluated after the document was created but before any of its scripts were run. This is useful to amend the JavaScript environment, e.g. to seed `Math.random`.
    # An example of overriding `Math.random` before the page loads:
    #
    #
    #
    # **NOTE** The order of evaluation of multiple scripts installed via `browserContext.addInitScript(script[, arg])` and `page.addInitScript(script[, arg])` is not defined.
    abstract def add_init_script(script : String, arg : Any) : Nil
    # Returns the browser instance of the context. If it was launched as a persistent context null gets returned.
    abstract def browser : Browser?
    # Clears context cookies.
    abstract def clear_cookies : Nil
    # Clears all permission overrides for the browser context.
    #
    abstract def clear_permissions : Nil
    # Closes the browser context. All the pages that belong to the browser context will be closed.
    #
    # **NOTE** the default browser context cannot be closed.
    abstract def close : Nil

    def cookies
      cookies(Array(String).new)
    end

    def cookies(url : String)
      cookies([url])
    end

    # If no URLs are specified, this method returns all cookies. If URLs are specified, only cookies that affect those URLs are returned.
    abstract def cookies(url : Array(String)) : Array(Cookie)

    def expose_binding(name : String, playwright_binding : Page::Binding) : Nil
      expose_binding(name, playwright_binding, nil)
    end

    # The method adds a function called `name` on the `window` object of every frame in every page in the context. When called, the function executes `playwrightBinding` and returns a Promise which resolves to the return value of `playwrightBinding`. If the `playwrightBinding` returns a Promise, it will be awaited.
    # The first argument of the `playwrightBinding` function contains information about the caller: `{ browserContext: BrowserContext, page: Page, frame: Frame }`.
    # See `page.exposeBinding(name, playwrightBinding[, options])` for page-only version.
    # An example of exposing page URL to all frames in all pages in the context:
    #
    # An example of passing an element handle:
    #
    abstract def expose_binding(name : String, playwright_binding : Page::Binding, options : ExposeBindingOptions?) : Nil
    # The method adds a function called `name` on the `window` object of every frame in every page in the context. When called, the function executes `playwrightFunction` and returns a Promise which resolves to the return value of `playwrightFunction`.
    # If the `playwrightFunction` returns a Promise, it will be awaited.
    # See `page.exposeFunction(name, playwrightFunction)` for page-only version.
    # An example of adding an `md5` function to all pages in the context:
    #
    abstract def expose_function(name : String, playwright_function : Page::Function) : Nil

    def grant_permissions(permissions : Array(String)) : Nil
      grant_permissions(permissions, nil)
    end

    # Grants specified permissions to the browser context. Only grants corresponding permissions to the given origin if specified.
    abstract def grant_permissions(permissions : Array(String), options : GrantPermissionsOptions?) : Nil
    # Creates a new page in the browser context.
    abstract def new_page : Page
    # Returns all open pages in the context. Non visible pages, such as `"background_page"`, will not be listed here. You can find them using `chromiumBrowserContext.backgroundPages()`.
    abstract def pages : Array(Page)
    abstract def route(url : String, handler : Consumer(Route))
    abstract def route(url : Regex, handler : Consumer(Route))
    # Routing provides the capability to modify network requests that are made by any page in the browser context. Once route is enabled, every request matching the url pattern will stall unless it's continued, fulfilled or aborted.
    # An example of a naïve handler that aborts all image requests:
    #
    # or the same snippet using a regex pattern instead:
    #
    # Page routes (set up with `page.route(url, handler)`) take precedence over browser context routes when request matches both handlers.
    #
    # **NOTE** Enabling routing disables http cache.
    abstract def route(url : (String) -> Bool, handler : Consumer(Route))
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
    # **NOTE** `page.setDefaultNavigationTimeout(timeout)` and `page.setDefaultTimeout(timeout)` take priority over `browserContext.setDefaultNavigationTimeout(timeout)`.
    abstract def set_default_navigation_timeout(timeout : Int32) : Nil
    # This setting will change the default maximum time for all the methods accepting `timeout` option.
    #
    # **NOTE** `page.setDefaultNavigationTimeout(timeout)`, `page.setDefaultTimeout(timeout)` and `browserContext.setDefaultNavigationTimeout(timeout)` take priority over `browserContext.setDefaultTimeout(timeout)`.
    abstract def set_default_timeout(timeout : Int32) : Nil
    # The extra HTTP headers will be sent with every request initiated by any page in the context. These headers are merged with page-specific extra HTTP headers set with `page.setExtraHTTPHeaders(headers)`. If page overrides a particular header, page-specific header value will be used instead of the browser context header value.
    #
    # **NOTE** `browserContext.setExtraHTTPHeaders` does not guarantee the order of headers in the outgoing requests.
    abstract def set_extra_http_headers(headers : Hash(String, String)) : Nil
    # Sets the context's geolocation. Passing `null` or `undefined` emulates position unavailable.
    #
    #
    # **NOTE** Consider using `browserContext.grantPermissions(permissions[, options])` to grant permissions for the browser context pages to read its geolocation.
    abstract def set_geolocation(geolocation : Geolocation?) : Nil
    abstract def set_offline(offline : Bool) : Nil

    def storage_state : StorageState
      storage_state(nil)
    end

    # Returns storage state for this browser context, contains current cookies and local storage snapshot.
    abstract def storage_state(options : StorageStateOptions?) : StorageState

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
    # Removes a route created with `browserContext.route(url, handler)`. When `handler` is not specified, removes all routes for the `url`.
    abstract def unroute(url : (String) -> Bool, handler : Consumer(Route)?)

    def wait_for_event(event : EventType) : Deferred(Event(EventType))
      wait_for_event(event, nil)
    end

    def wait_for_event(event : EventType, predicate : ((Event(EventType)) -> Bool)) : Deferred(Event(EventType))
      options = WaitForEventOptions.new
      options.predicate = predicate
      wait_for_event(event, options)
    end

    # Waits for event to fire and passes its value into the predicate function. Returns when the predicate returns truthy value. Will throw an error if the context closes before the event is fired. Returns the event data value.
    #
    abstract def wait_for_event(event : EventType, options : WaitForEventOptions?) : Deferred(Event(EventType))
  end
end
