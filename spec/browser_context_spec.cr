require "file_utils"
require "./spec_helper"

module Playwright
  @@persistent_context : BrowserContext?

  def self.persistent_context
    @@persistent_context.not_nil!
  end

  def self.launch_persistent
    launch_persistent(BrowserType::LaunchPersistentContextOptions.new)
  end

  def self.launch_persistent(options : BrowserType::LaunchPersistentContextOptions)
    fail "persistent context should be nil" unless @@persistent_context.nil?
    user_data_dir = Path.new(Dir.tempdir, "user-data-dir")
    FileUtils.mkdir_p(user_data_dir.to_s)
    context = browser_type.launch_persistent_context(user_data_dir, options)
    @@persistent_context = context
    context.pages[0]
  end

  describe BrowserContext do
    Spec.after_each {
      @@persistent_context.try &.close rescue nil
      @@persistent_context = nil
    }

    it "should support has touch option" do
      page = launch_persistent(BrowserType::LaunchPersistentContextOptions.new(has_touch: true))
      page.goto(server.prefix + "/mobile.html")
      page.evaluate("() => 'ontouchstart' in window").should be_true
    end

    it "should work in persistent context" do
      next if firefox? # Firefox does not support mobile
      page = launch_persistent(BrowserType::LaunchPersistentContextOptions.new(
        viewport: Page::ViewPort.new(420, 480), is_mobile: true))

      page.goto(server.prefix + "/empty.html")
      page.evaluate("() => window.innerWidth").should eq(980)
    end

    it "should support color scheme option" do
      page = launch_persistent(BrowserType::LaunchPersistentContextOptions.new(color_scheme: ColorScheme::DARK))
      page.evaluate("matchMedia('(prefers-color-scheme: light)').matches").should be_false
      page.evaluate("matchMedia('(prefers-color-scheme: dark)').matches").should be_true
    end

    it "should support timezone id option" do
      page = launch_persistent(BrowserType::LaunchPersistentContextOptions.new(
        locale: "en-US", timezone_id: "America/Jamaica"))
      page.evaluate("new Date(1609353508101).toString()").should eq("Wed Dec 30 2020 13:38:28 GMT-0500 (Eastern Standard Time)")
    end

    it "should support locale option" do
      page = launch_persistent(BrowserType::LaunchPersistentContextOptions.new(locale: "zh-CN"))
      page.evaluate("navigator.language").should eq("zh-CN")
    end

    it "should support geolocation and permission options" do
      page = launch_persistent(BrowserType::LaunchPersistentContextOptions.new(
        geolocation: Geolocation.new(10.0, 10.0),
        permissions: ["geolocation"]))
      page.goto(server.empty_page)
      geolocation = page.evaluate(%(
        () => new Promise(resolve => navigator.geolocation.getCurrentPosition(position => {
          resolve({latitude: position.coords.latitude, longitude: position.coords.longitude});
          }))
      ))
      geolocation.should eq({"latitude" => 10, "longitude" => 10})
    end

    it "should support extra http headers options" do
      page = launch_persistent(BrowserType::LaunchPersistentContextOptions.new(
        extra_http_headers: {"foo" => "bar"}))
      page.goto(server.empty_page)
    end

    it "should accept user data dir" do
      user_data_dir = Path.new(Dir.tempdir, "user-data-dir-tmp")
      FileUtils.mkdir_p(user_data_dir.to_s)
      context = browser_type.launch_persistent_context(user_data_dir)
      Dir.children(user_data_dir).size.should be > 0
      context.close
      Dir.children(user_data_dir).size.should be > 0
    end

    it "should restore state from user data dir" do
      user_data_dir = Path.new(Dir.tempdir, "user-data-dir-1")
      FileUtils.mkdir_p(user_data_dir.to_s)
      context = browser_type.launch_persistent_context(user_data_dir, nil)
      page = context.new_page
      page.goto(server.empty_page)
      page.evaluate("() => localStorage.hey = 'hello'")
      context.close

      context2 = browser_type.launch_persistent_context(user_data_dir, nil)
      page = context2.new_page
      page.goto(server.empty_page)
      page.evaluate("localStorage.hey").should eq("hello")
      context2.close
      user_data_dir = Path.new(Dir.tempdir, "user-data-dir-2")
      FileUtils.mkdir_p(user_data_dir.to_s)
      context3 = browser_type.launch_persistent_context(user_data_dir, nil)
      page = context3.new_page
      page.goto(server.empty_page)
      page.evaluate("localStorage.hey").should eq(nil)
      context3.close
    end

    # it "should restore cookies from user data dir" do
    #   user_data_dir = Path.new(Dir.tempdir, "user-data-dir-1")
    #   FileUtils.mkdir_p(user_data_dir.to_s)
    #   context = browser_type.launch_persistent_context(user_data_dir, nil)
    #   page = context.new_page
    #   cookie = page.evaluate(%(() => {
    #     document.cookie = 'doSomethingOnlyOnce=true; expires=Fri, 31 Dec 9999 23:59:59 GMT';
    #     return document.cookie;
    #   }))
    #   cookie.should eq("doSomethingOnlyOnce=true")
    #   context.close
    # end

    it "should have default URL when launching browser" do
      launch_persistent
      urls = persistent_context.pages.map(&.url)
      urls.should eq(["about:blank"])
    end

    it "should raise if page argument is passed" do
      next if firefox?
      options = BrowserType::LaunchPersistentContextOptions.new(args: [server.empty_page])
      user_data_dir = Path.new(Dir.tempdir, "user-data-dir-1")
      FileUtils.mkdir_p(user_data_dir.to_s)
      expect_raises(PlaywrightException, "Arguments can not specify page to be opened") do
        browser_type.launch_persistent_context(user_data_dir, options)
      end
    end

    it "should fire close event for a persistent context" do
      launch_persistent
      closed = [false]
      persistent_context.add_listener(BrowserContext::EventType::CLOSE, ListenerImpl(BrowserContext::EventType).new { |_| closed[0] = true })
      persistent_context.close
      closed[0].should be_true
    end

    it "should respect selectors" do
      page = launch_persistent
      default_context_css = %({
        create(root, target) {},
        query(root, selector) {
          return root.querySelector(selector);
        },
        queryAll(root, selector) {
          return Array.from(root.querySelectorAll(selector));
        }
      })

      playwright.selectors.register("defaultContextCSS", default_context_css)

      page.set_content("<div>hello</div>")
      page.inner_html("css=div").should eq("hello")
      page.inner_html("defaultContextCSS=div").should eq("hello")
    end
  end

  describe "BrowserContext And Cookies" do
    it "Test Browser Context And Cookies" do
      page.goto(server.empty_page)
      context.add_cookies([BrowserContext::AddCookie.new(url: server.empty_page, name: "password",
        value: "123456")])
      page.evaluate("document.cookie").should eq("password=123456")
    end

    it "Should Round Trip Cookie" do
      page.goto(server.empty_page)
      doc_cookie = page.evaluate(%(
        () => {
          const date = new Date('1/1/2038');
          document.cookie = `username=John Doe;expires=${date.toUTCString()}`;
          return document.cookie;
        }
      ))
      doc_cookie.should eq("username=John Doe")
      cookies = context.cookies
      context.clear_cookies
      context.cookies.size.should eq(0)
      context.add_cookies([BrowserContext::AddCookie.new(
        name: cookies[0].name,
        value: cookies[0].value,
        domain: cookies[0].domain,
        path: cookies[0].path,
        expires: cookies[0].expires
      )])

      cookies.to_json.should eq(context.cookies.to_json)
    end

    it "Should Isolate Cookies in Browser Contexts" do
      acontext = browser.new_context
      context.add_cookies([BrowserContext::AddCookie.new(
        url: server.empty_page,
        name: "isolatecookie",
        value: "page1value"
      )])
      acontext.add_cookies([BrowserContext::AddCookie.new(
        url: server.empty_page,
        name: "isolatecookie",
        value: "page2value"
      )])
      cookies1 = context.cookies
      cookies2 = acontext.cookies
      cookies1.size.should eq(1)
      cookies2.size.should eq(1)
      cookies1[0].name.should eq("isolatecookie")
      cookies1[0].value.should eq("page1value")
      cookies2[0].name.should eq("isolatecookie")
      cookies2[0].value.should eq("page2value")
      acontext.close
    end

    it "Should Isolate Cookies between launches" do
      browser1 = browser_type.launch
      context1 = browser1.new_context
      context1.add_cookies([BrowserContext::AddCookie.new(
        url: server.empty_page,
        name: "cookie-in-context-1",
        value: "value",
      )])
      browser1.close
      browser2 = browser_type.launch
      context2 = browser2.new_context
      cookies = context2.cookies
      cookies.size.should eq(0)
      browser2.close
    end

    it "Should send multiple cookies" do
      page.goto(server.empty_page)
      context.add_cookies([BrowserContext::AddCookie.new(
        url: server.empty_page,
        name: "multiple-1",
        value: "123456",
      ), BrowserContext::AddCookie.new(
        url: server.empty_page,
        name: "multiple-2",
        value: "bar",
      )])

      page.evaluate(%(
        () => {
          const cookies = document.cookie.split(';');
          return cookies.map(cookie => cookie.trim()).sort();
        }
      )).should eq(["multiple-1=123456", "multiple-2=bar"])
    end

    it "Should have Expires Set to 1 for session cookies" do
      context.add_cookies([BrowserContext::AddCookie.new(
        url: server.empty_page,
        name: "expires",
        value: "123456",
      )])
      context.cookies[0].expires.should eq(-1)
    end

    it "Should send cookie with reasonable defaults" do
      context.add_cookies([BrowserContext::AddCookie.new(
        url: server.empty_page,
        name: "defaults",
        value: "123456",
      )])
      cookies = context.cookies
      cookies[0].name.should eq("defaults")
      cookies[0].value.should eq("123456")
      cookies[0].domain.should eq("localhost")
      cookies[0].path.should eq("/")
      cookies[0].http_only.should eq(false)
      cookies[0].secure.should eq(false)
      cookies[0].same_site.should eq(BrowserContext::SameSite::NONE)
    end

    it "Should Set A Cookie with A Path" do
      page.goto(server.prefix + "/grid.html")
      context.add_cookies([BrowserContext::AddCookie.new(
        domain: "localhost",
        path: "/grid.html",
        name: "gridcookie",
        value: "GRID"
      )])
      cookies = context.cookies
      cookies[0].name.should eq("gridcookie")
      cookies[0].value.should eq("GRID")
      cookies[0].domain.should eq("localhost")
      cookies[0].path.should eq("/grid.html")
      cookies[0].http_only.should eq(false)
      cookies[0].secure.should eq(false)
      cookies[0].same_site.should eq(BrowserContext::SameSite::NONE)

      page.evaluate("document.cookie").should eq("gridcookie=GRID")
      page.goto(server.empty_page)
      page.evaluate("document.cookie").should eq("")
      page.goto(server.prefix + "/grid.html")
      page.evaluate("document.cookie").should eq("gridcookie=GRID")
    end

    it "Should not Set A Cookie with blank page url" do
      expect_raises(PlaywrightException, %(Blank page can not have cookie "example-cookie-blank")) do
        context.add_cookies([BrowserContext::AddCookie.new(
          url: server.empty_page,
          name: "multiple-1",
          value: "123456",
        ), BrowserContext::AddCookie.new(
          url: "about:blank",
          name: "example-cookie-blank",
          value: "best",
        )])
      end
    end

    it "Should not Set A Cookie On Data URL page" do
      expect_raises(PlaywrightException, %( Data URL page can not have cookie "example-cookie-data")) do
        context.add_cookies([BrowserContext::AddCookie.new(
          url: "data:,Hello%2C%20World!",
          name: "example-cookie-data",
          value: "best",
        )])
      end
    end

    it "Should default to setting secure cookies for HTTPS Websites" do
      page.goto(server.empty_page)
      secure_url = "https://example.com"
      context.add_cookies([BrowserContext::AddCookie.new(url: secure_url, name: "foo", value: "bar")])
      cookies = context.cookies(secure_url)
      cookies.size.should eq(1)
      cookies[0].secure.should be_true
    end

    it "Should be able to set unsecure cookies for HTTP Websites" do
      page.goto(server.empty_page)
      http_url = "http://example.com"
      context.add_cookies([BrowserContext::AddCookie.new(url: http_url, name: "foo", value: "bar")])
      cookies = context.cookies(http_url)
      cookies.size.should eq(1)
      cookies[0].secure.should be_false
    end

    it "Should set cookies for a frame" do
      page.goto(server.empty_page)
      context.add_cookies([BrowserContext::AddCookie.new(url: server.prefix, name: "frame-cookie", value: "value")])
      page.evaluate(%(
        src => {
          let fulfill;
          const promise = new Promise(x => fulfill = x);
          const iframe = document.createElement(`iframe`);
          document.body.appendChild(iframe);
          iframe.onload = fulfill;
          iframe.src = src;
          return promise;
        }
      ), "/grid.html")
      page.frames[1].evaluate("document.cookie").should eq("frame-cookie=value")
    end

    it "Should Not Block Third Party Cookies" do
      page.goto(server.empty_page)
      page.evaluate(%(
        src => {
          let fulfill;
          const promise = new Promise(x => fulfill = x);
          const iframe = document.createElement(`iframe`);
          document.body.appendChild(iframe);
          iframe.onload = fulfill;
          iframe.src = src;
          return promise;
        }
      ), server.cross_process_prefix + "/grid.html")
      page.frames[1].evaluate("document.cookie = 'username=John Doe'")
      page.wait_for_timeout(2000)
      allows_third_party = chromium? || firefox?
      cookies = context.cookies(server.cross_process_prefix + "/grid.html")
      if allows_third_party
        cookies[0].name.should eq("username")
        cookies[0].value.should eq("John Doe")
        cookies[0].domain.should eq("127.0.0.1")
        cookies[0].path.should eq("/")
        cookies[0].expires.should eq(-1)
        cookies[0].http_only.should eq(false)
        cookies[0].secure.should eq(false)
        cookies[0].same_site.should eq(BrowserContext::SameSite::NONE)
      else
        cookies.size.should eq(0)
      end
    end

    it "Should Clear Cookies" do
      page.goto(server.empty_page)
      context.add_cookies([BrowserContext::AddCookie.new(url: server.empty_page, name: "foo", value: "bar")])
      page.evaluate("document.cookie").should eq("foo=bar")
      context.clear_cookies
      context.cookies.size.should eq(0)
      page.reload
      page.evaluate("document.cookie").should eq("")
    end

    it "Should Isolate cookies when clearing" do
      acontext = browser.new_context
      context.add_cookies([BrowserContext::AddCookie.new(url: server.empty_page, name: "page1cookie", value: "page1value")])
      acontext.add_cookies([BrowserContext::AddCookie.new(url: server.empty_page, name: "page2cookie", value: "page2value")])
      context.cookies.size.should eq(1)
      acontext.cookies.size.should eq(1)
      context.clear_cookies
      context.cookies.size.should eq(0)
      acontext.cookies.size.should eq(1)
      acontext.clear_cookies
      context.cookies.size.should eq(0)
      acontext.cookies.size.should eq(0)
      acontext.close
    end

    it "Test expose bindings" do
      binding_source = Array(Page::Binding::Source).new
      context.expose_binding("add", PageBindingProc.new { |source, args|
        binding_source << source
        args[0].as(JSON::Any).as_i64 + args[1].as(JSON::Any).as_i64
      })
      page = context.new_page
      result = page.evaluate("add(5,6)")
      context.should eq(binding_source[0].context)
      page.should eq(binding_source[0].page)
      page.main_frame.should eq(binding_source[0].frame)
      result.should eq(11)
    end

    it "Test expose function" do
      context.expose_function("add", PageFunctionProc.new { |args|
        args[0].as(JSON::Any).as_i64 + args[1].as(JSON::Any).as_i64
      })
      page = context.new_page
      page.expose_function("mul", PageFunctionProc.new { |args|
        args[0].as(JSON::Any).as_i64 * args[1].as(JSON::Any).as_i64
      })
      context.expose_function("sub", PageFunctionProc.new { |args|
        args[0].as(JSON::Any).as_i64 - args[1].as(JSON::Any).as_i64
      })
      context.expose_binding("addHandle", PageBindingProc.new { |source, args|
        source.frame.evaluate_handle("([a, b]) => a + b", args)
      })
      result = page.evaluate("async () => ({ mul: await mul(9, 4), add: await add(9, 4), sub: await sub(9, 4), addHandle: await addHandle(5, 6) })")
      result.should eq({"mul" => 36, "add" => 13, "sub" => 5, "addHandle" => 11})
    end

    it "Should raise for Duplicate registrations" do
      context.expose_function("foo", PageFunctionProc.new { |_| nil })
      context.expose_function("bar", PageFunctionProc.new { |_| nil })
      expect_raises(PlaywrightException, %(Function "foo" has been already registered)) do
        context.expose_function("foo", PageFunctionProc.new { |_| nil })
      end

      page = context.new_page
      expect_raises(PlaywrightException, %(Function "foo" has been already registered in browser context)) do
        page.expose_function("foo", PageFunctionProc.new { |_| nil })
      end

      page.expose_function("baz", PageFunctionProc.new { |_| nil })
      expect_raises(PlaywrightException, %(Function "baz" has been already registered in one of the pages)) do
        context.expose_function("baz", PageFunctionProc.new { |_| nil })
      end
    end

    it "Should be callable from inside add_init_script" do
      actual = Array(Any).new
      context.expose_function("woof", PageFunctionProc.new { |args| actual << args[0]; true })
      context.add_init_script("window['woof']('context')")
      page = context.new_page
      page.add_init_script("window['woof']('page')")
      actual.clear
      page.reload
      actual.should eq(["context", "page"])
    end

    it "expose_binding handle should work" do
      target = Array(JSHandle).new
      context.expose_binding("logme", PageBindingProc.new { |_, args|
        target << args[0].as(JSHandle)
        17_i64
      }, BrowserContext::ExposeBindingOptions.new(handle: true))
      page = context.new_page
      result = page.evaluate("async function(){ return window['logme']({ foo: 42 });}")
      target[0].should_not be_nil
      target[0].evaluate("x => x.foo").should eq(42)
      result.should eq(17)
    end

    it "should raise for missing global proxy" do
      next unless chromium?
      options = create_launch_options
      options.proxy = BrowserType::LaunchOptions::Proxy.new("per-context")
      launch_browser(options)

      browser1 = browser_type.launch(create_launch_options)
      begin
        expect_raises(PlaywrightException, "Browser needs to be launched with the global proxy.") do
          browser1.new_context(Browser::NewContextOptions.new(
            proxy: Browser::NewContextOptions::Proxy.new(server: "localhost:#{server.port}")))
        end
      ensure
        browser1.close
      end
    end

    describe "BrowserContext Route" do
      it "should intercept" do
        context1 = browser.new_context
        intercepted = [] of Bool
        page = context1.new_page
        context1.route("**/empty.html", Consumer(Route).new { |route|
          intercepted << true
          request = route.request
          request.url.includes?("empty.html")
          request.headers["user-agent"]?.should_not be_nil
          request.method.should eq("GET")
          request.post_data.should be_nil
          request.is_navigation_request.should be_true
          request.resource_type.should eq("document")
          page.main_frame.should eq(request.frame)
          request.frame.url.should eq("about:blank")
          route.continue
        })

        response = page.goto(server.empty_page)
        response.try &.ok.should be_true
        intercepted[0].should be_true
        context1.close
      end

      it "should unroute" do
        context = browser.new_context
        page = context.new_page
        intercepted = Array(Int32).new
        handler1 = Consumer(Route).new { |route|
          intercepted << 1
          route.continue
        }
        context.route("**/empty.html", handler1)
        context.route("**/empty.html", Consumer(Route).new { |route|
          intercepted << 2
          route.continue
        })
        context.route("**/empty.html", Consumer(Route).new { |route|
          intercepted << 3
          route.continue
        })
        context.route("**/*", Consumer(Route).new { |route|
          intercepted << 4
          route.continue
        })
        page.goto(server.empty_page)
        intercepted.should eq([1])

        intercepted.clear
        context.unroute("**/empty.html", handler1)
        page.goto(server.empty_page)
        intercepted.should eq([2])

        intercepted.clear
        context.unroute("**/empty.html")
        page.goto(server.empty_page)
        intercepted.should eq([4])
        context.close
      end

      it "should yield to page route" do
        context = browser.new_context
        context.route("**/empty.html", Consumer(Route).new { |route|
          route.fulfill(Route::FulfillResponse.new(status: 200, body: "context"))
        })
        page = context.new_page
        page.route("**/empty.html", Consumer(Route).new { |route|
          route.fulfill(Route::FulfillResponse.new(status: 200, body: "page"))
        })
        response = page.goto(server.empty_page)
        response.try &.ok.should be_true
        response.try &.text.should eq("page")
        context.close
      end

      it "should fallback to context route" do
        context = browser.new_context
        context.route("**/empty.html", Consumer(Route).new { |route|
          route.fulfill(Route::FulfillResponse.new(status: 200, body: "context"))
        })
        page = context.new_page
        page.route("**/non-empty.html", Consumer(Route).new { |route|
          route.fulfill(Route::FulfillResponse.new(status: 200, body: "page"))
        })
        response = page.goto(server.empty_page)
        response.try &.ok.should be_true
        response.try &.text.should eq("context")
        context.close
      end
    end

    describe "BrowserContext StorageState" do
      it "should capture local storage" do
        page.route("**/*", Consumer(Route).new { |route|
          route.fulfill(Route::FulfillResponse.new(body: "<html></html>"))
        })

        page.goto("https://www.example.com")
        page.evaluate("localStorage['name1'] = 'value1';")
        page.goto("https://www.domain.com")
        page.evaluate("localStorage['name2'] = 'value2';")

        storage = context.storage_state
        result = %q([{"origin":"https://www.example.com","localStorage":[{"name":"name1","value":"value1"}]},{"origin":"https://www.domain.com","localStorage":[{"name":"name2","value":"value2"}]}])
        storage.origins.to_json.should eq(result)
      end

      it "should set local storage" do
        storage = BrowserContext::StorageState.new
        storage.origins << BrowserContext::StorageState::OriginState.new(
          "https://www.example.com",
          [BrowserContext::StorageState::OriginState::LocalStorageItem.new("name1", "value1")])
        context = browser.new_context(Browser::NewContextOptions.new.with_storage_state(storage))
        page = context.new_page
        page.route("**/*", Consumer(Route).new { |route|
          route.fulfill(Route::FulfillResponse.new(body: "<html></html>"))
        })
        page.goto("https://www.example.com")
        localstorage = page.evaluate("window.localStorage")
        localstorage.should eq({"name1" => "value1"})
      end
    end
  end
end
