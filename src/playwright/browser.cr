require "path"
require "json"

module Playwright
  # A Browser is created when Playwright connects to a browser instance, either through `browserType.launch([options])` or `browserType.connect(params)`.
  # An example of using a Browser to create a Page:
  #
  # See ChromiumBrowser, FirefoxBrowser and WebKitBrowser for browser-specific features. Note that `browserType.connect(params)` and `browserType.launch([options])` always return a specific browser instance, based on the browser being connected to or launched.
  module Browser
    class VideoSize
      include JSON::Serializable
      getter width : Int32
      getter height : Int32

      def initialize(@width, @height)
      end
    end

    enum EventType
      DISCONNECTED
    end

    abstract def add_listener(type : EventType, listener : Listener(EventType))
    abstract def remove_listener(type : EventType, listener : Listener(EventType))

    class NewContextOptions
      include JSON::Serializable

      class RecordHar
        include JSON::Serializable
        # Optional setting to control whether to omit request content from the HAR. Defaults to `false`.
        @[JSON::Field(key: "omitContent")]
        property omit_content : Bool?
        # Path on the filesystem to write the HAR file to.
        @[JSON::Field(key: "path")]
        property path : Path

        def initialize(@path, @omit_content = nil)
        end
      end

      class RecordVideo
        include JSON::Serializable
        # Path to the directory to put videos into.
        @[JSON::Field(key: "dir")]
        property dir : Path
        # Optional dimensions of the recorded videos. If not specified the size will be equal to `viewport`. If `viewport` is not configured explicitly the video size defaults to 1280x720. Actual picture of each page will be scaled down if necessary to fit the specified size.
        @[JSON::Field(key: "size")]
        property size : VideoSize?

        def initialize(@dir, @size = nil)
        end
      end

      class Proxy
        include JSON::Serializable
        # Proxy to be used for all requests. HTTP and SOCKS proxies are supported, for example `http://myproxy.com:3128` or `socks5://myproxy.com:3128`. Short form `myproxy.com:3128` is considered an HTTP proxy.
        @[JSON::Field(key: "server")]
        property server : String
        # Optional coma-separated domains to bypass proxy, for example `".com, chromium.org, .domain.com"`.
        @[JSON::Field(key: "bypass")]
        property bypass : String?
        # Optional username to use if HTTP proxy requires authentication.
        @[JSON::Field(key: "username")]
        property username : String?
        # Optional password to use if HTTP proxy requires authentication.
        @[JSON::Field(key: "password")]
        property password : String?

        def initialize(@server, @bypass = nil, @username = nil, @password = nil)
        end
      end

      # Whether to automatically download all the attachments. Defaults to `false` where all the downloads are canceled.
      @[JSON::Field(key: "acceptDownloads")]
      property accept_downloads : Bool?
      # Whether to ignore HTTPS errors during navigation. Defaults to `false`.
      @[JSON::Field(key: "ignoreHTTPSErrors")]
      property ignore_https_errors : Bool?
      # Toggles bypassing page's Content-Security-Policy.
      @[JSON::Field(key: "bypassCSP")]
      property bypass_csp : Bool?
      # Sets a consistent viewport for each page. Defaults to an 1280x720 viewport. `null` disables the default viewport.
      @[JSON::Field(key: "viewport")]
      property viewport : Page::ViewPort?
      # Specific user agent to use in this context.
      @[JSON::Field(key: "userAgent")]
      property user_agent : String?
      # Specify device scale factor (can be thought of as dpr). Defaults to `1`.
      @[JSON::Field(key: "deviceScaleFactor")]
      property device_scale_factor : Int32?
      # Whether the `meta viewport` tag is taken into account and touch events are enabled. Defaults to `false`. Not supported in Firefox.
      @[JSON::Field(key: "isMobile")]
      property is_mobile : Bool?
      # Specifies if viewport supports touch events. Defaults to false.
      @[JSON::Field(key: "hasTouch")]
      property has_touch : Bool?
      # Whether or not to enable JavaScript in the context. Defaults to `true`.
      @[JSON::Field(key: "javaScriptEnabled")]
      property java_script_enabled : Bool?
      # Changes the timezone of the context. See ICU’s `metaZones.txt` for a list of supported timezone IDs.
      @[JSON::Field(key: "timezoneId")]
      property timezone_id : String?
      @[JSON::Field(key: "geolocation")]
      property geolocation : Geolocation?
      # Specify user locale, for example `en-GB`, `de-DE`, etc. Locale will affect `navigator.language` value, `Accept-Language` request header value as well as number and date formatting rules.
      @[JSON::Field(key: "locale")]
      property locale : String?
      # A list of permissions to grant to all pages in this context. See `browserContext.grantPermissions(permissions[, options])` for more details.
      @[JSON::Field(key: "permissions")]
      property permissions : Array(String)?
      # An object containing additional HTTP headers to be sent with every request. All header values must be strings.
      @[JSON::Field(key: "extraHTTPHeaders")]
      property extra_http_headers : Hash(String, String)?
      # Whether to emulate network being offline. Defaults to `false`.
      @[JSON::Field(key: "offline")]
      property offline : Bool?
      # Credentials for HTTP authentication.
      @[JSON::Field(key: "httpCredentials")]
      property http_credentials : BrowserContext::HTTPCredentials?
      # Emulates `'prefers-colors-scheme'` media feature, supported values are `'light'`, `'dark'`, `'no-preference'`. See `page.emulateMedia(params)` for more details. Defaults to '`light`'.
      @[JSON::Field(key: "colorScheme")]
      property color_scheme : ColorScheme?
      # Logger sink for Playwright logging.
      @[JSON::Field(key: "logger", ignore: true)]
      property logger : Logger?
      # Enables HAR recording for all pages into `recordHar.path` file. If not specified, the HAR is not recorded. Make sure to await `browserContext.close()` for the HAR to be saved.
      @[JSON::Field(key: "recordHar")]
      property record_har : RecordHar?
      # Enables video recording for all pages into `recordVideo.dir` directory. If not specified videos are not recorded. Make sure to await `browserContext.close()` for videos to be saved.
      @[JSON::Field(key: "recordVideo")]
      property record_video : RecordVideo?
      # Network proxy settings to use with this context. Note that browser needs to be launched with the global proxy for this option to work. If all contexts override the proxy, global proxy will be never used and can be any string, for example `launch({ proxy: { server: 'per-context' } })`.
      @[JSON::Field(key: "proxy")]
      property proxy : Proxy?
      # Populates context with given storage state. This method can be used to initialize context with logged-in information obtained via `browserContext.storageState([options])`. Either a path to the file with saved storage, or an object with the following fields:
      @[JSON::Field(key: "storageState")]
      property storage_state : BrowserContext::StorageState?
      @[JSON::Field(ignore: true)]
      property storage_state_path : Path?

      def initialize(@accept_downloads = nil, @ignore_https_errors = nil, @bypass_csp = nil, @viewport = nil, @user_agent = nil, @device_scale_factor = nil, @is_mobile = nil, @has_touch = nil, @java_script_enabled = nil, @timezone_id = nil, @geolocation = nil, @locale = nil, @permissions = nil, @extra_http_headers = nil, @offline = nil, @http_credentials = nil, @color_scheme = nil, @logger = nil, @record_har = nil, @record_video = nil, @proxy = nil, @storage_state = nil)
      end

      def with_storage_state(state : BrowserContext::StorageState)
        self.storage_state = state
        self.storage_state_path = nil
        self
      end

      def with_storage_state(path : Path)
        self.storage_state = nil
        self.storage_state_path = path
        self
      end
    end

    class NewPageOptions
      include JSON::Serializable

      class RecordHar
        include JSON::Serializable
        # Optional setting to control whether to omit request content from the HAR. Defaults to `false`.
        @[JSON::Field(key: "omitContent")]
        property omit_content : Bool?
        # Path on the filesystem to write the HAR file to.
        @[JSON::Field(key: "path")]
        property path : Path

        def initialize(@path, @omit_content = nil)
        end
      end

      class RecordVideo
        include JSON::Serializable
        # Path to the directory to put videos into.
        @[JSON::Field(key: "dir")]
        property dir : Path
        # Optional dimensions of the recorded videos. If not specified the size will be equal to `viewport`. If `viewport` is not configured explicitly the video size defaults to 1280x720. Actual picture of each page will be scaled down if necessary to fit the specified size.
        @[JSON::Field(key: "size")]
        property size : VideoSize?

        def initialize(@dir, @size = nil)
        end
      end

      class Proxy
        include JSON::Serializable
        # Proxy to be used for all requests. HTTP and SOCKS proxies are supported, for example `http://myproxy.com:3128` or `socks5://myproxy.com:3128`. Short form `myproxy.com:3128` is considered an HTTP proxy.
        @[JSON::Field(key: "server")]
        property server : String
        # Optional coma-separated domains to bypass proxy, for example `".com, chromium.org, .domain.com"`.
        @[JSON::Field(key: "bypass")]
        property bypass : String?
        # Optional username to use if HTTP proxy requires authentication.
        @[JSON::Field(key: "username")]
        property username : String?
        # Optional password to use if HTTP proxy requires authentication.
        @[JSON::Field(key: "password")]
        property password : String?

        def initialize(@server, @bypass = nil, @username = nil, @password = nil)
        end
      end

      # Whether to automatically download all the attachments. Defaults to `false` where all the downloads are canceled.
      @[JSON::Field(key: "acceptDownloads")]
      property accept_downloads : Bool?
      # Whether to ignore HTTPS errors during navigation. Defaults to `false`.
      @[JSON::Field(key: "ignoreHTTPSErrors")]
      property ignore_https_errors : Bool?
      # Toggles bypassing page's Content-Security-Policy.
      @[JSON::Field(key: "bypassCSP")]
      property bypass_csp : Bool?
      # Sets a consistent viewport for each page. Defaults to an 1280x720 viewport. `null` disables the default viewport.
      @[JSON::Field(key: "viewport")]
      property viewport : Page::ViewPort?
      # Specific user agent to use in this context.
      @[JSON::Field(key: "userAgent")]
      property user_agent : String?
      # Specify device scale factor (can be thought of as dpr). Defaults to `1`.
      @[JSON::Field(key: "deviceScaleFactor")]
      property device_scale_factor : Int32?
      # Whether the `meta viewport` tag is taken into account and touch events are enabled. Defaults to `false`. Not supported in Firefox.
      @[JSON::Field(key: "isMobile")]
      property is_mobile : Bool?
      # Specifies if viewport supports touch events. Defaults to false.
      @[JSON::Field(key: "hasTouch")]
      property has_touch : Bool?
      # Whether or not to enable JavaScript in the context. Defaults to `true`.
      @[JSON::Field(key: "javaScriptEnabled")]
      property java_script_enabled : Bool?
      # Changes the timezone of the context. See ICU’s `metaZones.txt` for a list of supported timezone IDs.
      @[JSON::Field(key: "timezoneId")]
      property timezone_id : String?
      @[JSON::Field(key: "geolocation")]
      property geolocation : Geolocation?
      # Specify user locale, for example `en-GB`, `de-DE`, etc. Locale will affect `navigator.language` value, `Accept-Language` request header value as well as number and date formatting rules.
      @[JSON::Field(key: "locale")]
      property locale : String?
      # A list of permissions to grant to all pages in this context. See `browserContext.grantPermissions(permissions[, options])` for more details.
      @[JSON::Field(key: "permissions")]
      property permissions : Array(String)?
      # An object containing additional HTTP headers to be sent with every request. All header values must be strings.
      @[JSON::Field(key: "extraHTTPHeaders")]
      property extra_http_headers : Hash(String, String)?
      # Whether to emulate network being offline. Defaults to `false`.
      @[JSON::Field(key: "offline")]
      property offline : Bool?
      # Credentials for HTTP authentication.
      @[JSON::Field(key: "httpCredentials")]
      property http_credentials : BrowserContext::HTTPCredentials?
      # Emulates `'prefers-colors-scheme'` media feature, supported values are `'light'`, `'dark'`, `'no-preference'`. See `page.emulateMedia(params)` for more details. Defaults to '`light`'.
      @[JSON::Field(key: "colorScheme")]
      property color_scheme : ColorScheme?
      # Logger sink for Playwright logging.
      @[JSON::Field(key: "logger", ignore: true)]
      property logger : Logger?
      # Enables HAR recording for all pages into `recordHar.path` file. If not specified, the HAR is not recorded. Make sure to await `browserContext.close()` for the HAR to be saved.
      @[JSON::Field(key: "recordHar")]
      property record_har : RecordHar?
      # Enables video recording for all pages into `recordVideo.dir` directory. If not specified videos are not recorded. Make sure to await `browserContext.close()` for videos to be saved.
      @[JSON::Field(key: "recordVideo")]
      property record_video : RecordVideo?
      # Network proxy settings to use with this context. Note that browser needs to be launched with the global proxy for this option to work. If all contexts override the proxy, global proxy will be never used and can be any string, for example `launch({ proxy: { server: 'per-context' } })`.
      @[JSON::Field(key: "proxy")]
      property proxy : Proxy?
      # Populates context with given storage state. This method can be used to initialize context with logged-in information obtained via `browserContext.storageState([options])`. Either a path to the file with saved storage, or an object with the following fields:
      @[JSON::Field(key: "storageState")]
      property storage_state : BrowserContext::StorageState?
      @[JSON::Field(ignore: true)]
      property storage_state_path : Path?

      def initialize(@accept_downloads = nil, @ignore_https_errors = nil, @bypass_csp = nil, @viewport = nil, @user_agent = nil, @device_scale_factor = nil, @is_mobile = nil, @has_touch = nil, @java_script_enabled = nil, @timezone_id = nil, @geolocation = nil, @locale = nil, @permissions = nil, @extra_http_headers = nil, @offline = nil, @http_credentials = nil, @color_scheme = nil, @logger = nil, @record_har = nil, @record_video = nil, @proxy = nil, @storage_state = nil)
      end

      def with_storage_state(state : BrowserContext::StorageState)
        self.storage_state = state
        self.storage_state_path = nil
        self
      end

      def with_storage_state(path : Path)
        self.storage_state = nil
        self.storage_state_path = path
        self
      end
    end

    # In case this browser is obtained using `browserType.launch([options])`, closes the browser and all of its pages (if any were opened).
    # In case this browser is obtained using `browserType.connect(params)`, clears all created contexts belonging to this browser and disconnects from the browser server.
    # The Browser object itself is considered to be disposed and cannot be used anymore.
    abstract def close : Nil
    # Returns an array of all open browser contexts. In a newly created browser, this will return zero browser contexts.
    #
    abstract def contexts : Array(BrowserContext)
    # Indicates that the browser is connected.
    abstract def is_connected : Bool

    def new_context : BrowserContext
      new_context(nil)
    end

    # Creates a new browser context. It won't share cookies/cache with other browser contexts.
    #
    abstract def new_context(options : NewContextOptions?) : BrowserContext

    def new_page : Page
      new_page(nil)
    end

    # Creates a new page in a new browser context. Closing this page will close the context as well.
    # This is a convenience API that should only be used for the single-page scenarios and short snippets. Production code and testing frameworks should explicitly create `browser.newContext([options])` followed by the `browserContext.newPage()` to control their exact life times.
    abstract def new_page(options : NewPageOptions?) : Page
    # Returns the browser version.
    abstract def version : String
  end
end
