require "./spec_helper"

module Playwright
  describe "Page Check" do
    it "shoud check the box" do
      page.set_content(%(<input id='checkbox' type='checkbox'></input>))
      page.check("input")
      page.evaluate(%( () => window['checkbox'].checked)).should be_true
    end

    it "shoud not check the checkbox" do
      page.set_content(%(<input id='checkbox' type='checkbox' checked></input>))
      page.check("input")
      page.evaluate(%( () => window['checkbox'].checked)).should be_true
    end

    it "shoud uncheck the checkbox" do
      page.set_content(%(<input id='checkbox' type='checkbox' checked></input>))
      page.uncheck("input")
      page.evaluate(%( () => window['checkbox'].checked)).should be_false
    end

    it "should check the box by label" do
      page.set_content(%(<label for='checkbox'><input id='checkbox' type='checkbox'></input></label>))
      page.check("label")
      page.evaluate(%( () => window['checkbox'].checked)).should be_true
    end

    it "should check the box outside label" do
      page.set_content(%(<label for='checkbox'>Text</label><div><input id='checkbox' type='checkbox'></input></div>))
      page.check("label")
      page.evaluate(%( () => window['checkbox'].checked)).should be_true
    end

    it "should check the box inside label" do
      page.set_content(%(<label>Text<span><input id='checkbox' type='checkbox'></input></span></label>))
      page.check("label")
      page.evaluate(%( () => window['checkbox'].checked)).should be_true
    end

    it "should check the radio" do
      page.set_content(%(
        <input type='radio'>one</input>
        <input id='two' type='radio'>two</input>
        <input type='radio'>three</input>
      ))

      page.check("#two")
      page.evaluate(%( () => window['two'].checked)).should be_true
    end

    it "should check the box by ariarole" do
      page.set_content(%(
        <div role='checkbox' id='checkbox'>CHECKBOX</div>
          <script>
          checkbox.addEventListener('click', () => checkbox.setAttribute('aria-checked', 'true'));
          </script>
      ))

      page.check("div")
      page.evaluate(%( () => window['checkbox'].getAttribute('aria-checked'))).should eq "true"
    end
  end

  describe "Page Click" do
    it "should click the button" do
      page.goto(server.prefix + "/input/button.html")
      page.click("button")
      page.evaluate("result").should eq("Clicked")
    end

    it "should click svg" do
      page.set_content(%(
        <svg height='100' width='100'>
          <circle onclick='javascript:window.__CLICKED=42' cx='50' cy='50' r='40' stroke='black' stroke-width='3' fill='red'/>
        </svg>
      ))

      page.click("circle")
      page.evaluate("__CLICKED").should eq(42)
    end

    it "should click the button if window node is removed" do
      page.goto(server.prefix + "/input/button.html")
      page.evaluate("() => delete window.Node")
      page.click("button")
      page.evaluate("result").should eq("Clicked")
    end

    it "should click on a span with an inline element inside" do
      page.set_content(%(
        <style>
          span::before {
            content: 'q'
          }
        </style>
        <span onclick='javascript:window.CLICKED=42'></span>
      ))

      page.click("span")
      page.evaluate("CLICKED").should eq(42)
    end

    it "should click the 1x1 div" do
      page.set_content(%(<div style='width: 1px; height: 1px;' onclick='window.__clicked = true'></div>))
      page.click("div")
      page.evaluate("window.__clicked").should be_true
    end

    it "should click the button after navigation" do
      page.goto(server.prefix + "/input/button.html")
      page.click("button")
      page.goto(server.prefix + "/input/button.html")
      page.click("button")
      page.evaluate("result").should eq("Clicked")
    end

    it "should click the button after cross origin navigation" do
      page.goto(server.prefix + "/input/button.html")
      page.click("button")
      page.goto(server.cross_process_prefix + "/input/button.html")
      page.click("button")
      page.evaluate("result").should eq("Clicked")
    end

    it "should click with disabled javascript" do
      context = browser.new_context(Browser::NewContextOptions.new(java_script_enabled: false))
      page = context.new_page
      page.goto(server.prefix + "/wrappedlink.html")

      nav_promise = page.wait_for_navigation
      page.click("a")
      nav_promise.get
      page.url.should eq(server.prefix + "/wrappedlink.html#clicked")
      context.close
    end

    it "should click when one of inline box children is outside of viewport" do
      page.set_content(%(
        <style>
          i {
            position: absolute;
            top: -1000px;
          }
        </style>
        <span onclick='javascript:window.CLICKED = 42;'><i>woof</i><b>doggo</b></span>
      ))
      page.click("span")
      page.evaluate("CLICKED").should eq(42)
    end

    it "should select the text by triple clicking" do
      page.goto(server.prefix + "/input/textarea.html")
      text = "This is the text that we are going to try to select. Let's see how it goes."
      page.fill("textarea", text)
      page.click("textarea", Page::ClickOptions.new(click_count: 3))
      page.evaluate(%(
        () => {
          const textarea = document.querySelector('textarea');
          return textarea.value.substring(textarea.selectionStart, textarea.selectionEnd);
        }
      )).should eq(text)
    end

    it "should click offscreen buttons" do
      page.goto(server.prefix + "/offscreenbuttons.html")
      messages = [] of String
      page.add_listener(Page::EventType::CONSOLE, ListenerImpl(Page::EventType).new { |event|
        messages << event.data.as(ConsoleMessage).text
      })
      10.times do |i|
        page.evaluate("() => window.scrollTo(0,0)")
        page.click("#btn#{i}")
      end

      messages.should eq([
        "button #0 clicked",
        "button #1 clicked",
        "button #2 clicked",
        "button #3 clicked",
        "button #4 clicked",
        "button #5 clicked",
        "button #6 clicked",
        "button #7 clicked",
        "button #8 clicked",
        "button #9 clicked",
      ])
    end

    it "should wait for visible when already visible" do
      page.goto(server.prefix + "/input/button.html")
      page.click("button")
      page.evaluate("result").should eq("Clicked")
    end

    it "should not wait with force" do
      page.goto(server.prefix + "/input/button.html")
      page.eval_on_selector("button", "b => b.style.display = 'none'")
      begin
        page.click("button", Page::ClickOptions.new(force: true))
      rescue ex : PlaywrightException
        excep = ex
      end

      excep.should_not be_nil
      excep.not_nil!.message.not_nil!.includes?("Element is not visible").should be_true
      page.evaluate("result").should eq("Was not clicked")
    end

    it "should click wrapped links" do
      page.goto(server.prefix + "/wrappedlink.html")
      page.click("a")
      page.evaluate("__clicked").should be_true
    end

    it "should click on checkbox input and toggle" do
      page.goto(server.prefix + "/input/checkbox.html")
      page.evaluate("() => window['result'].check").should eq(nil)
      page.click("input#agree")
      page.evaluate("() => window['result'].check").should be_true
      page.evaluate("() => window['result'].events").should eq([
        "mouseover",
        "mouseenter",
        "mousemove",
        "mousedown",
        "mouseup",
        "click",
        "input",
        "change",
      ])
      page.click("input#agree")
      page.evaluate("() => window['result'].check").should be_false
    end

    it "should click on checkbox label and toggle" do
      page.goto(server.prefix + "/input/checkbox.html")
      page.evaluate("() => window['result'].check").should eq(nil)
      page.click("label[for='agree']")
      page.evaluate("() => window['result'].check").should be_true
      page.evaluate("() => window['result'].events").should eq([
        "click",
        "input",
        "change",
      ])
      page.click("input#agree")
      page.evaluate("() => window['result'].check").should be_false
    end

    it "should not hang with touch enabled viewports" do
      # https://github.com/GoogleChrome/puppeteer/issues/161
      descriptor = playwright.devices["iPhone 6"]
      context = browser.new_context(Browser::NewContextOptions.new(viewport: Page::ViewPort.new(
        descriptor.viewport.width, descriptor.viewport.height), has_touch: descriptor.has_touch
      ))
      page = context.new_page
      page.mouse.down
      page.mouse.move(100, 10)
      page.mouse.up
      context.close
    end

    it "should scroll and click the button" do
      page.goto(server.prefix + "/input/scrollable.html")
      page.click("#button-5")
      page.evaluate("() => document.querySelector('#button-5').textContent").should eq("clicked")
      page.click("#button-80")
      page.evaluate("() => document.querySelector('#button-80').textContent").should eq("clicked")
    end

    it "should double click the button" do
      page.goto(server.prefix + "/input/button.html")
      page.evaluate(%(
        () => {
          window['double'] = false;
          const button = document.querySelector('button');
          button.addEventListener('dblclick', event => {
            window['double'] = true;
          });
      }
      ))
      page.dblclick("button")
      page.evaluate("double").should be_true
      page.evaluate("result").should eq("Clicked")
    end

    it "should click a partially obscured button" do
      page.goto(server.prefix + "/input/button.html")
      page.evaluate(%( () => {
        const button = document.querySelector('button');
        button.textContent = 'Some really long text that will go offscreen';
        button.style.position = 'absolute';
        button.style.left = '368px';
      }))
      page.click("button")
      page.evaluate("() => window['result']").should eq("Clicked")
    end

    it "should click a rotated button" do
      page.goto(server.prefix + "/input/rotatedButton.html")
      page.click("button")
      page.evaluate("result").should eq("Clicked")
    end

    it "should fire context menu event on right click" do
      page.goto(server.prefix + "/input/scrollable.html")
      page.click("#button-8", Page::ClickOptions.new(button: Mouse::Button::RIGHT))
      page.evaluate("() => document.querySelector('#button-8').textContent").should eq("context menu")
    end

    it "should click links which cause navigation" do
      # https://github.com/GoogleChrome/puppeteer/issues/206
      page.set_content(%(<a href="#{server.empty_page}">empty.html</a>))
      # this should not hang
      page.click("a")
    end

    it "should click the button inside an iframe" do
      page.goto(server.empty_page)
      page.set_content("<div style='width:100px;height:100px'>spacer</div>")
      attach_frame(page, "button-test", server.prefix + "/input/button.html")
      frame = page.frames[1]
      button = frame.query_selector("button")
      button.not_nil!.click
      frame.evaluate("() => window['result']").should eq("Clicked")
    end

    it "should click the button with fixed position inside an iframe" do
      next unless firefox?
      # https://github.com/GoogleChrome/puppeteer/issues/4110
      # https://bugs.chromium.org/p/chromium/issues/detail?id=986390
      # https://chromium-review.googlesource.com/c/chromium/src/+/1742784
      page.goto(server.empty_page)
      page.set_viewport_size(500, 500)
      page.set_content("<div style='width:100px;height:2000px'>spacer</div>")
      attach_frame(page, "button-test", server.cross_process_prefix + "/input/button.html")
      frame = page.frames[1]
      frame.eval_on_selector("button", "button => button.style.setProperty('position', 'fixed')")
      frame.click("button")
      frame.evaluate("() => window['result']").should eq("Clicked")
    end

    it "should click the button with device scale factor set" do
      context = browser.new_context(Browser::NewContextOptions.new(viewport: Page::ViewPort.new(400, 400),
        device_scale_factor: 5))
      page = context.new_page
      page.evaluate("() => window.devicePixelRatio").should eq(5)
      page.set_content("<div style='width:100px;height:100px'>spacer</div>")
      attach_frame(page, "button-test", server.prefix + "/input/button.html")
      frame = page.frames[1]
      button = frame.query_selector("button")
      button.not_nil!.click
      frame.evaluate("window['result']").should eq("Clicked")
      context.close
    end

    it "should click the button with px border with offset" do
      page.goto(server.prefix + "/input/button.html")
      page.eval_on_selector("button", "button => button.style.borderWidth = '8px'")
      page.click("button", Page::ClickOptions.new.with_position(20, 10))
      page.evaluate("result").should eq("Clicked")
      # Safari reports border-relative offsetX/offsetY
      page.evaluate("offsetX").should eq(webkit? ? 20 + 8 : 20)
      page.evaluate("offsetY").should eq(webkit? ? 10 + 8 : 10)
    end

    it "should click a very large button with offset" do
      page.goto(server.prefix + "/input/button.html")
      page.eval_on_selector("button", "button => button.style.borderWidth = '8px'")
      page.eval_on_selector("button", "button => button.style.height = button.style.width = '2000px'")
      page.click("button", Page::ClickOptions.new.with_position(1900, 1910))
      page.evaluate("() => window['result']").should eq("Clicked")
      # Safari reports border-relative offsetX/offsetY
      page.evaluate("offsetX").should eq(webkit? ? 1900 + 8 : 1900)
      page.evaluate("offsetY").should eq(webkit? ? 1910 + 8 : 1910)
    end

    it "should click a buttin in scrolling container with offset" do
      page.goto(server.prefix + "/input/button.html")
      page.eval_on_selector("button", %(button => {
        const container = document.createElement('div');
        container.style.overflow = 'auto';
        container.style.width = '200px';
        container.style.height = '200px';
        button.parentElement.insertBefore(container, button);
        container.appendChild(button);
        button.style.height = '2000px';
        button.style.width = '2000px';
        button.style.borderWidth = '8px';
      }))
      page.click("button", Page::ClickOptions.new.with_position(1900, 1910))
      page.evaluate("() => window['result']").should eq("Clicked")
      # Safari reports border-relative offsetX/offsetY
      page.evaluate("offsetX").should eq(webkit? ? 1900 + 8 : 1900)
      page.evaluate("offsetY").should eq(webkit? ? 1910 + 8 : 1910)
    end

    it "should click the button with offset with page scale" do
      next if firefox?
      context = browser.new_context(Browser::NewContextOptions.new(viewport: Page::ViewPort.new(400, 400),
        is_mobile: true))
      page = context.new_page
      page.goto(server.prefix + "/input/button.html")
      page.eval_on_selector("button", %(button => {
        button.style.borderWidth = '8px';
        document.body.style.margin = '0';
      }))
      page.click("button", Page::ClickOptions.new.with_position(20, 10))
      page.evaluate("result").should eq("Clicked")
      # 20;10 + 8px of border in each direction
      expected_x = 28
      expected_y = 18
      if webkit?
        # Webkit rounds up during css -> dip -> conversion
        expected_x = 29
        expected_y = 19
      elsif chromium? && !headful?
        # Headless Chromium rounds down during css -> dip -> css conversion
        expected_x = 27
        expected_y = 18
      end

      (page.evaluate("pageX").as(JSON::Any).as_i + 0.01).round.should eq(expected_x)
      (page.evaluate("pageY").as(JSON::Any).as_i + 0.01).round.should eq(expected_y)

      context.close
    end

    it "should wait for stable position" do
      page.goto(server.prefix + "/input/button.html")
      page.eval_on_selector("button", %(button => {
        button.style.transition = 'margin 500ms linear 0s';
        button.style.marginLeft = '200px';
        button.style.borderWidth = '0';
        button.style.width = '200px';
        button.style.height = '20px';
        // Set display to 'block' - otherwise Firefox layouts with non-even
        // values on Linux.
        button.style.display = 'block';
        document.body.style.margin = '0';
    }))

      page.click("button")
      page.evaluate("result").should eq("Clicked")
      page.evaluate("pageX").should eq(300)
      page.evaluate("pageY").should eq(10)
    end

    it "should fail when obscured and not waiting for hit target" do
      page.goto(server.prefix + "/input/button.html")
      button = page.query_selector("button")
      page.evaluate(%(() => {
        document.body.style.position = 'relative';
        const blocker = document.createElement('div');
        blocker.style.position = 'absolute';
        blocker.style.width = '400px';
        blocker.style.height = '20px';
        blocker.style.left = '0';
        blocker.style.top = '0';
        document.body.appendChild(blocker);
      }))
      button.not_nil!.click(ElementHandle::ClickOptions.new(force: true))
      page.evaluate("window['result']").should eq("Was not clicked")
    end

    it "should click disabled div" do
      page.set_content("<div onclick='javascript:window.__CLICKED=true;' disabled>Click target</div>")
      page.click("text=Click target")
      page.evaluate("__CLICKED").should be_true
    end

    it "should climb DOM for inner label with pointer-events:none" do
      page.set_content("<button onclick='javascript:window.__CLICKED=true;'><label style='pointer-events:none'>Click target</label></button>")
      page.click("text=Click target")
      page.evaluate("__CLICKED").should be_true
    end

    it "should update modifiers correctly" do
      page.goto(server.prefix + "/input/button.html")
      page.click("button", Page::ClickOptions.new(modifiers: Set{Keyboard::Modifier::SHIFT}))
      page.evaluate("shiftKey").should be_true
      page.click("button", Page::ClickOptions.new(modifiers: Set(Keyboard::Modifier).new))
      page.evaluate("shiftKey").should be_false

      page.keyboard.down("Shift")
      page.click("button", Page::ClickOptions.new(modifiers: Set(Keyboard::Modifier).new))
      page.evaluate("shiftKey").should be_false
      page.click("button")
      page.evaluate("shiftKey").should be_true
      page.keyboard.up("Shift")
      page.click("button")
      page.evaluate("shiftKey").should be_false
    end

    it "should click offscreen element when scroll behavior is smooth" do
      page.set_content(%(
        <div style='border: 1px solid black; height: 500px; overflow: auto; width: 500px; scroll-behavior: smooth'>
        <button style='margin-top: 2000px' onClick='window.clicked = true'>hi</button>
        </div>
      ))

      page.click("button")
      page.evaluate("window.clicked").should be_true
    end

    it "should report nice error when element is detached and force clicked" do
      page.goto(server.prefix + "/input/animating-button.html")
      page.evaluate("addButton()")
      handle = page.query_selector("button")
      page.evaluate("stopButton(true)")
      expect_raises(PlaywrightException, "Element is not attached to the DOM") do
        handle.not_nil!.click(ElementHandle::ClickOptions.new(force: true))
      end
      page.evaluate("window.clicked").should eq(nil)
    end

    it "should dispatch micro tasks in order" do
      page.set_content(%(
        <button id=button>Click me</button>
        <script>
        let mutationCount = 0;
        const observer = new MutationObserver((mutationsList, observer) => {
          for(let mutation of mutationsList)
          ++mutationCount;
        });
        observer.observe(document.body, { attributes: true, childList: true, subtree: true });
        button.addEventListener('mousedown', () => {
          mutationCount = 0;
          document.body.appendChild(document.createElement('div'));
        });
        button.addEventListener('mouseup', () => {
          window['result'] = mutationCount;
        });
      </script>
      ))

      page.click("button")
      page.evaluate("() => window['result']").should eq(1)
    end

    it "should click the button when window inner width is corrupted" do
      page.goto(server.prefix + "/input/button.html")
      page.evaluate("() => Object.defineProperty(window, 'innerWidth', {value: 0})")
      page.click("button")
      page.evaluate("result").should eq("Clicked")
    end
  end

  describe "Page Basics" do
    it "should reject all promises when page is closed" do
      new_page = context.new_page
      new_page.close
      expect_raises(PlaywrightException, "Protocol error") do
        new_page.evaluate("() => new Promise(r => {})")
      end
    end

    it "should not be visible in context pages" do
      new_page = context.new_page
      context.pages.includes?(new_page).should be_true
      new_page.close
      context.pages.includes?(new_page).should be_false
    end

    it "should run beforeunload if asked for" do
      new_page = context.new_page
      new_page.goto(server.prefix + "/beforeunload.html")
      # We have to interact with a page so that "beforeunload" handlers fire
      new_page.click("body")
      did_show_dialog = [false]
      new_page.add_listener(Page::EventType::DIALOG, ListenerImpl(Page::EventType).new { |event|
        did_show_dialog[0] = true
        dialog = event.data.as(Dialog)
        dialog.type.should eq(Dialog::Type::BEFOREUNLOAD)
        dialog.default_value.should eq("")
        if chromium?
          dialog.message.should eq("")
        elsif webkit?
          dialog.message.should eq("Leave?")
        else
          dialog.message.should eq("This page is asking you to confirm that you want to leave - data you have entered may not be saved.")
        end
        dialog.accept
      })
      new_page.close(Page::CloseOptions.new(run_before_unload: true))
      # did_show_dialog[0].should be_true
    end

    it "should not run before unload by default" do
      page = context.new_page
      page.goto(server.prefix + "/beforeunload.html")
      # We have to interact with a page so that "beforeunload" handlers fire
      page.click("body")
      did_show_dialog = [false]
      page.add_listener(Page::EventType::DIALOG, ListenerImpl(Page::EventType).new { |_|
        did_show_dialog[0] = true
      })
      page.close
      did_show_dialog[0].should be_false
    end

    it "should set the page close state" do
      page = context.new_page
      page.is_closed.should be_false
      page.close
      page.is_closed.should be_true
    end

    it "should terminate network waiters" do
      page = context.new_page
      request = page.wait_for_request(server.empty_page)
      response = page.wait_for_response(server.empty_page)
      page.close
      begin
        request.get
        fail "exception expected, but got none"
      rescue ex
        ex.message.not_nil!.includes?("Page closed").should be_true
        ex.message.not_nil!.includes?("Timeout").should be_false
      end
      begin
        response.get
        fail "exception expected, but got none"
      rescue ex
        ex.message.not_nil!.includes?("Page closed").should be_true
        ex.message.not_nil!.includes?("Timeout").should be_false
      end
    end

    it "should be callable twice" do
      page1 = context.new_page
      page1.close
      page1.close
      page1.close
    end

    it "should fire load when expected" do
      page.goto("about:blank")
      page.wait_for_load_state(Page::LoadState::LOAD).get
    end

    it "should provide access to the opener page" do
      event = page.wait_for_event(Page::EventType::POPUP)
      page.evaluate("() => window.open('about:blank')")
      popup = event.get.data.as(Page)
      opener = popup.opener
      page.should eq(opener)
    end

    it "should return nil if parent page has been closed" do
      event = page.wait_for_event(Page::EventType::POPUP)
      page.evaluate("() => window.open('about:blank')")
      popup = event.get.data.as(Page)
      page.close
      opener = popup.opener
      opener.should be_nil
    end

    it "should fire domcontentloaded when expected" do
      page.goto("about:blank")
      page.wait_for_load_state(Page::LoadState::DOMCONTENTLOADED).get
    end

    it "page url should work" do
      page.goto(server.empty_page + "#hash")
      page.url.should eq(server.empty_page + "#hash")
      page.evaluate(%(() => {
        window.location.hash = 'dynamic';
      }))
      page.url.should eq(server.empty_page + "#dynamic")
    end

    it "should return page title" do
      page.goto(server.prefix + "/title.html")
      page.title.should eq("Woof-Woof")
    end

    it "page close should work with window close" do
      new_event = page.wait_for_event(Page::EventType::POPUP)
      page.evaluate("() => window['newPage'] = window.open('about:blank')")
      new_page = new_event.get.data.as(Page)
      close_event = new_page.wait_for_event(Page::EventType::CLOSE)
      page.evaluate("() => window['newPage'].close()")
      close_event.get
    end

    it "page close should work with page close" do
      new_page = context.new_page
      close_event = new_page.wait_for_event(Page::EventType::CLOSE)
      new_page.close
      close_event.get
    end

    it "page context should return the correct instance" do
      context.should eq(page.context)
    end

    it "page frame should respect name" do
      page.set_content("<iframe name=target></iframe>")
      page.frame_by_name("bogus").should be_nil
      frame = page.frame_by_name("target") || fail "unable to get target frame"
      page.main_frame.child_frames[0].should eq(frame)
    end

    it "page frame should respect url" do
      page.set_content("<iframe src='#{server.empty_page}'></iframe>")
      page.frame_by_url(/bogus/).should be_nil
      frame = page.frame_by_url(Regex.new(".*empty.*")) || fail "unable to get frame"
      frame.url.should eq(server.empty_page)
    end

    it "should have sane user agent" do
      ua = page.evaluate("() => navigator.userAgent").as_s
      parts = ua.split(/[()]/).map(&.strip)
      # First part is always Mozilla/5.0'
      parts[0].should eq("Mozilla/5.0")
      # Second part in parenthesis is platform - ignore it

      # Third part for Firefox is the last one and encodes engine and browser versions.
      if firefox?
        engine_and_browser = parts[2].split(" ")
        engine_and_browser[0].starts_with?("Gecko").should be_true
        engine_and_browser[1].starts_with?("Firefox").should be_true
        next
      end

      # For both chromium and webkit, third part is the AppleWebKit version
      parts[2].starts_with?("AppleWebKit/").should be_true
      parts[3].should eq("KHTML, like Gecko")

      # 5th part encodes real browser name and engine version
      engine_and_browser = parts[4].split(" ")
      engine_and_browser[1].starts_with?("Safari").should be_true
      if chromium?
        engine_and_browser[0].includes?("Chrome/").should be_true
      else
        engine_and_browser[0].starts_with?("Version/").should be_true
      end
    end

    it "page press should work" do
      page.goto(server.prefix + "/input/textarea.html")
      page.press("textarea", "a")
      page.evaluate("() => document.querySelector('textarea').value").should eq("a")
    end

    it "page press should work for enter" do
      page.set_content("<input onkeypress='console.log(\"press\")'></input>")
      messages = [] of ConsoleMessage
      page.add_listener(Page::EventType::CONSOLE, ListenerImpl(Page::EventType).new { |event|
        messages << event.data.as(ConsoleMessage)
      })
      page.press("input", "Enter")
      messages[0].text.should eq("press")
    end

    it "frame press should work" do
      page.set_content("<iframe name=inner src='#{server.prefix}/input/textarea.html'></iframe>")
      frame = page.frame_by_name("inner") || fail "unable to get frame"
      frame.press("textarea", "a")
      frame.evaluate("() => document.querySelector('textarea').value").should eq("a")
    end

    it "frame focus should work multiple times" do
      next if firefox?
      [context.new_page, context.new_page].each do |p|
        p.set_content("<button id='foo' onfocus='window.gotFocus=true'></button>")
        p.focus("#foo")
        p.evaluate("() => !!window['gotFocus']").should be_true
      end
    end
  end

  describe "Page EmulateMedia" do
    it "should emulate type" do
      page.evaluate("() => matchMedia('screen').matches").should be_true
      page.evaluate("() => matchMedia('print').matches").should be_false
      page.emulate_media(Page::EmulateMediaParams.new(media: Page::EmulateMediaParams::Media::PRINT))
      page.evaluate("() => matchMedia('screen').matches").should be_false
      page.evaluate("() => matchMedia('print').matches").should be_true
      page.emulate_media(Page::EmulateMediaParams.new)
      page.evaluate("() => matchMedia('screen').matches").should be_false
      page.evaluate("() => matchMedia('print').matches").should be_true
      page.emulate_media(Page::EmulateMediaParams.new(media: Page::EmulateMediaParams::Media::NULL))
      page.evaluate("() => matchMedia('screen').matches").should be_true
      page.evaluate("() => matchMedia('print').matches").should be_false
    end

    it "should emulate scheme work" do
      page.emulate_media(Page::EmulateMediaParams.new(color_scheme: ColorScheme::LIGHT))
      page.evaluate("() => matchMedia('(prefers-color-scheme: light)').matches").should be_true
      page.evaluate("() => matchMedia('(prefers-color-scheme: dark)').matches").should be_false
      page.emulate_media(Page::EmulateMediaParams.new(color_scheme: ColorScheme::DARK))
      page.evaluate("() => matchMedia('(prefers-color-scheme: light)').matches").should be_false
      page.evaluate("() => matchMedia('(prefers-color-scheme: dark)').matches").should be_true
    end

    it "should default to light" do
      page.evaluate("() => matchMedia('(prefers-color-scheme: light)').matches").should be_true
      page.evaluate("() => matchMedia('(prefers-color-scheme: dark)').matches").should be_false
      page.emulate_media(Page::EmulateMediaParams.new(color_scheme: ColorScheme::DARK))
      page.evaluate("() => matchMedia('(prefers-color-scheme: light)').matches").should be_false
      page.evaluate("() => matchMedia('(prefers-color-scheme: dark)').matches").should be_true
      page.emulate_media(Page::EmulateMediaParams.new(color_scheme: ColorScheme::NULL))
      page.evaluate("() => matchMedia('(prefers-color-scheme: light)').matches").should be_true
      page.evaluate("() => matchMedia('(prefers-color-scheme: dark)').matches").should be_false
    end
  end

  describe "Page Evaluate" do
    it "test page evaluate" do
      page.evaluate("() => 7 * 3").should eq(21)
    end

    it "should transfer NaN" do
      page.evaluate("a => a", Float64::NAN).as_f.nan?.should be_true
    end

    it "should transfer infinity" do
      page.evaluate("a => a", Float64::INFINITY).as_f.infinite?.should eq(1)
    end

    it "should round trip unserialized values" do
      value = {"infinity" => Float64::INFINITY,
               "nZero"    => -0.0,
               "nan"      => Float64::NAN}

      res = page.evaluate("value => value", value).as_h
      res["infinity"].as_f.infinite?.should eq(1)
      res["nZero"].as_f.should eq(-0.0)
      res["nan"].as_f.nan?.should be_true
    end

    it "should return undefined for objects with symbols" do
      page.evaluate("() => [Symbol('foo64')]").should eq([nil])
    end

    it "should work with unicode chars" do
      page.evaluate("a => a['中文字符']", {"中文字符" => 42}).should eq(42)
    end

    it "should raise when evaluation triggers reload" do
      expect_raises(PlaywrightException, "navigation") do
        page.evaluate(%(() => {
          location.reload();
          return new Promise(() => {});
        }))
      end
    end

    it "should await promise" do
      res = page.evaluate("() => Promise.resolve(8 * 7)")
      res.should eq(56)
    end

    it "should work right after frame navigated" do
      frames = [] of JSON::Any
      page.add_listener(Page::EventType::FRAMENAVIGATED, ListenerImpl(Page::EventType).new { |evt|
        frame = evt.data.as(Frame)
        frames << frame.evaluate("() => 6 * 7")
      })

      page.goto(server.empty_page)
      frames[0].should eq(42)
    end

    it "should work from inside an exposed function" do
      # setup inpage callback, which calls page.evaluate
      page.expose_function("callController", PageFunctionProc.new { |args|
        page.evaluate("({ a, b }) => a * b", {"a" => args[0].as(JSON::Any),
                                              "b" => args[1].as(JSON::Any)})
      })

      res = page.evaluate(%(async function() {
        return await window['callController'](9,3);
      }))

      res.should eq(27)
    end

    it "should reject promise with exceptions" do
      expect_raises(PlaywrightException, "not_existing_object") do
        page.evaluate("() => not_existing_object.property")
      end
    end

    it "should support thrown numbers as error messages" do
      expect_raises(PlaywrightException, "100500") do
        page.evaluate("() => { throw 100500; }")
      end
    end

    it "should property serialize nil arguments" do
      page.evaluate("x => x", nil).should eq(nil)
    end

    it "should be able to raise tricky error" do
      handle = page.evaluate_handle("() => window")
      err_text : String? = nil
      begin
        handle.json_value
      rescue ex
        err_text = ex.message
      end
      err_text || fail "no exception raised"
      expect_raises(PlaywrightException, err_text.not_nil!) do
        page.evaluate(%(errorText => {
            throw new Error(errorText);
          }), err_text)
      end
    end

    it "should accept a string" do
      page.evaluate("1 + 2").should eq(3)
    end

    it "should accept a string with semicolons" do
      page.evaluate("1 + 5;").should eq(6)
    end

    it "should accept a string with comments" do
      page.evaluate(%(
        1 + 2;
        // do some math!
      )).should eq(3)
    end

    it "should accept elementhandle as argument" do
      page.set_content("<section>42</section>")
      elem = page.query_selector("section")
      page.evaluate("e => e.textContent", elem).should eq("42")
    end

    it "should raise if any underlying element was disposed" do
      page.set_content("<section>42</section>")
      elem = page.query_selector("section") || fail "element not found"
      elem.dispose
      expect_raises(PlaywrightException, "JSHandle is disposed") do
        page.evaluate("e => e.textContent", elem).should eq("42")
      end
    end

    it "should transfer 100MB of data from page to nodejs" do
      # This is too slow with wire
      next if ENV["NO_TRANSFER_TEST"]? # skip this test on CI

      a = page.evaluate("() => Array(100 * 1024 * 1024 + 1).join('a')").as_s
      a.size.should eq(100 * 1024 * 1024)
      a.each_char_with_index do |c, i|
        fail "unexpected char at position #{i}" unless c == 'a'
      end
    end
  end

  describe "Page Popup" do
    it "should inherit offline from browser context" do
      ctx = browser.new_context
      page1 = ctx.new_page
      page1.goto(server.empty_page)
      ctx.set_offline(true)
      online = page1.evaluate(%(url => {
        const win = window.open(url);
        return win.navigator.onLine;
      }), server.prefix + "/dummy.html")
      ctx.close
      online.should be_false
    end
  end
end
