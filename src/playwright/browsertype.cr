require "path"
require "json"

module Playwright
  # BrowserType provides methods to launch a specific browser instance or connect to an existing one. The following is a typical example of using Playwright to drive automation:
  #
  module BrowserType
    class LaunchOptions
      include JSON::Serializable

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

      # Whether to run browser in headless mode. More details for Chromium and Firefox. Defaults to `true` unless the `devtools` option is `true`.
      @[JSON::Field(key: "headless")]
      property headless : Bool?
      # Path to a browser executable to run instead of the bundled one. If `executablePath` is a relative path, then it is resolved relative to the current working directory. Note that Playwright only works with the bundled Chromium, Firefox or WebKit, use at your own risk.
      @[JSON::Field(key: "executablePath")]
      property executable_path : Path?
      # Additional arguments to pass to the browser instance. The list of Chromium flags can be found here.
      @[JSON::Field(key: "args")]
      property args : Array(String)?
      # If `true`, Playwright does not pass its own configurations args and only uses the ones from `args`. If an array is given, then filters out the given default arguments. Dangerous option; use with care. Defaults to `false`.
      @[JSON::Field(key: "ignoreDefaultArgs")]
      property ignore_default_args : Bool?
      # Network proxy settings.
      @[JSON::Field(key: "proxy")]
      property proxy : Proxy?
      # If specified, accepted downloads are downloaded into this directory. Otherwise, temporary directory is created and is deleted when browser is closed.
      @[JSON::Field(key: "downloadsPath")]
      property downloads_path : Path?
      # Enable Chromium sandboxing. Defaults to `false`.
      @[JSON::Field(key: "chromiumSandbox")]
      property chromium_sandbox : Bool?
      # Firefox user preferences. Learn more about the Firefox user preferences at `about:config`.
      @[JSON::Field(key: "firefoxUserPrefs")]
      property firefox_user_prefs : String?
      # Close the browser process on Ctrl-C. Defaults to `true`.
      @[JSON::Field(key: "handleSIGINT")]
      property handle_sigint : Bool?
      # Close the browser process on SIGTERM. Defaults to `true`.
      @[JSON::Field(key: "handleSIGTERM")]
      property handle_sigterm : Bool?
      # Close the browser process on SIGHUP. Defaults to `true`.
      @[JSON::Field(key: "handleSIGHUP")]
      property handle_sighup : Bool?
      # Logger sink for Playwright logging.
      @[JSON::Field(key: "logger", ignore: true)]
      property logger : Logger?
      # Maximum time in milliseconds to wait for the browser instance to start. Defaults to `30000` (30 seconds). Pass `0` to disable timeout.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?
      # Specify environment variables that will be visible to the browser. Defaults to `process.env`.
      @[JSON::Field(key: "env")]
      property env : String?
      # **Chromium-only** Whether to auto-open a Developer Tools panel for each tab. If this option is `true`, the `headless` option will be set `false`.
      @[JSON::Field(key: "devtools")]
      property devtools : Bool?
      # Slows down Playwright operations by the specified amount of milliseconds. Useful so that you can see what is going on.
      @[JSON::Field(key: "slowMo")]
      property slow_mo : Int32?

      def initialize(@headless = nil, @executable_path = nil, @args = nil, @ignore_default_args = nil, @proxy = nil, @downloads_path = nil, @chromium_sandbox = nil, @firefox_user_prefs = nil, @handle_sigint = nil, @handle_sigterm = nil, @handle_sighup = nil, @logger = nil, @timeout = nil, @env = nil, @devtools = nil, @slow_mo = nil)
      end
    end

    class LaunchPersistentContextOptions
      include JSON::Serializable

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

        class Size
          include JSON::Serializable
          # Video frame width.
          @[JSON::Field(key: "width")]
          property width : Int32
          # Video frame height.
          @[JSON::Field(key: "height")]
          property height : Int32

          def initialize(@width, @height)
          end
        end

        # Path to the directory to put videos into.
        @[JSON::Field(key: "dir")]
        property dir : Path
        # Optional dimensions of the recorded videos. If not specified the size will be equal to `viewport`. If `viewport` is not configured explicitly the video size defaults to 1280x720. Actual picture of each page will be scaled down if necessary to fit the specified size.
        @[JSON::Field(key: "size")]
        property size : Size?

        def initialize(@dir, @size = nil)
        end
      end

      # Whether to run browser in headless mode. More details for Chromium and Firefox. Defaults to `true` unless the `devtools` option is `true`.
      @[JSON::Field(key: "headless")]
      property headless : Bool?
      # Path to a browser executable to run instead of the bundled one. If `executablePath` is a relative path, then it is resolved relative to the current working directory. **BEWARE**: Playwright is only guaranteed to work with the bundled Chromium, Firefox or WebKit, use at your own risk.
      @[JSON::Field(key: "executablePath")]
      property executable_path : Path?
      # Additional arguments to pass to the browser instance. The list of Chromium flags can be found here.
      @[JSON::Field(key: "args")]
      property args : Array(String)?
      # If `true`, then do not use any of the default arguments. If an array is given, then filter out the given default arguments. Dangerous option; use with care. Defaults to `false`.
      @[JSON::Field(key: "ignoreDefaultArgs")]
      property ignore_default_args : String?
      # Network proxy settings.
      @[JSON::Field(key: "proxy")]
      property proxy : Proxy?
      # If specified, accepted downloads are downloaded into this directory. Otherwise, temporary directory is created and is deleted when browser is closed.
      @[JSON::Field(key: "downloadsPath")]
      property downloads_path : Path?
      # Enable Chromium sandboxing. Defaults to `true`.
      @[JSON::Field(key: "chromiumSandbox")]
      property chromium_sandbox : Bool?
      # Close the browser process on Ctrl-C. Defaults to `true`.
      @[JSON::Field(key: "handleSIGINT")]
      property handle_sigint : Bool?
      # Close the browser process on SIGTERM. Defaults to `true`.
      @[JSON::Field(key: "handleSIGTERM")]
      property handle_sigterm : Bool?
      # Close the browser process on SIGHUP. Defaults to `true`.
      @[JSON::Field(key: "handleSIGHUP")]
      property handle_sighup : Bool?
      # Maximum time in milliseconds to wait for the browser instance to start. Defaults to `30000` (30 seconds). Pass `0` to disable timeout.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?
      # Specify environment variables that will be visible to the browser. Defaults to `process.env`.
      @[JSON::Field(key: "env")]
      property env : String?
      # **Chromium-only** Whether to auto-open a Developer Tools panel for each tab. If this option is `true`, the `headless` option will be set `false`.
      @[JSON::Field(key: "devtools")]
      property devtools : Bool?
      # Slows down Playwright operations by the specified amount of milliseconds. Useful so that you can see what is going on. Defaults to 0.
      @[JSON::Field(key: "slowMo")]
      property slow_mo : Int32?
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

      def initialize(@headless = nil, @executable_path = nil, @args = nil, @ignore_default_args = nil, @proxy = nil, @downloads_path = nil, @chromium_sandbox = nil, @handle_sigint = nil, @handle_sigterm = nil, @handle_sighup = nil, @timeout = nil, @env = nil, @devtools = nil, @slow_mo = nil, @accept_downloads = nil, @ignore_https_errors = nil, @bypass_csp = nil, @viewport = nil, @user_agent = nil, @device_scale_factor = nil, @is_mobile = nil, @has_touch = nil, @java_script_enabled = nil, @timezone_id = nil, @geolocation = nil, @locale = nil, @permissions = nil, @extra_http_headers = nil, @offline = nil, @http_credentials = nil, @color_scheme = nil, @logger = nil, @record_har = nil, @record_video = nil)
      end
    end

    # A path where Playwright expects to find a bundled browser executable.
    abstract def executable_path : String

    def launch : Browser
      launch(nil)
    end

    # Returns the browser instance.
    # You can use `ignoreDefaultArgs` to filter out `--mute-audio` from default arguments:
    #
    #
    # **Chromium-only** Playwright can also be used to control the Chrome browser, but it works best with the version of Chromium it is bundled with. There is no guarantee it will work with any other version. Use `executablePath` option with extreme caution.
    # If Google Chrome (rather than Chromium) is preferred, a Chrome Canary or Dev Channel build is suggested.
    # In `browserType.launch([options])` above, any mention of Chromium also applies to Chrome.
    # See `this article` for a description of the differences between Chromium and Chrome. `This article` describes some differences for Linux users.
    abstract def launch(options : LaunchOptions?) : Browser

    def launch_persistent_context(user_data_dir : Path) : BrowserContext
      launch_persistent_context(user_data_dir, nil)
    end

    # Returns the persistent browser context instance.
    # Launches browser that uses persistent storage located at `userDataDir` and returns the only context. Closing this context will automatically close the browser.
    abstract def launch_persistent_context(user_data_dir : Path, options : LaunchPersistentContextOptions?) : BrowserContext
    # Returns browser name. For example: `'chromium'`, `'webkit'` or `'firefox'`.
    abstract def name : String
  end
end
