require "./spec_helper"

module Playwright
  describe ElementHandle do
    it "should work" do
      next if firefox? && headful?
      page.set_viewport_size(500, 500)
      page.goto(server.prefix + "/grid.html")
      elem = page.query_selector(".box:nth-of-type(13)") || fail "element not found"
      box = elem.bounding_box || fail "bounding_box not found"
      box.x.should eq(100)
      box.y.should eq(50)
      box.width.should eq(50)
      box.height.should eq(50)
    end

    it "should handle nested frames" do
      page.set_viewport_size(500, 500)
      page.goto(server.prefix + "/frames/nested-frames.html")
      frame = page.frame_by_name("dos") || fail "frame 'dos' not found"
      elem = frame.query_selector("div") || fail "div not found in frame"
      box = elem.bounding_box || fail "bounding_box not found"
      box.x.should eq(24)
      box.y.should eq(224)
      box.width.should eq(268)
      box.height.should eq(18)
    end

    it "should return nil for invisible elements" do
      page.set_content("<div style='display:none'>hi</div>")
      page.query_selector("div").try &.bounding_box.should be_nil
    end

    it "should force a layout" do
      page.set_viewport_size(500, 500)
      page.set_content("<div style='width: 100px; height: 100px'>hello</div>")
      elem = page.query_selector("div") || fail "div not found"
      page.evaluate("element => element.style.height = '200px'", elem)
      box = elem.bounding_box || fail "bounding_box not found"
      box.x.should eq(8)
      box.y.should eq(8)
      box.width.should eq(100)
      box.height.should eq(200)
    end

    it "should work with SVG nodes" do
      page.set_content(%(
        <svg xmlns='http://www.w3.org/2000/svg' width='500' height='500'>
        <rect id='theRect' x='30' y='50' width='200' height='300'></rect>
        </svg>
      ))
      elem = page.query_selector("#theRect") || fail "element not found"
      box = elem.bounding_box || fail "bounding_box not found"

      web = page.evaluate(%( e => {
        const rect = e.getBoundingClientRect();
        return {x: rect.x, y: rect.y, width: rect.width, height: rect.height};
      }), elem)

      web["x"].as_i.should eq(box.x)
      web["y"].as_i.should eq(box.y)
      web["width"].as_i.should eq(box.width)
      web["height"].as_i.should eq(box.height)
    end
  end

  describe "ElementHandle::Click" do
    it "should work" do
      page.goto(server.prefix + "/input/button.html")
      button = page.query_selector("button") || fail "button not found"
      button.click
      page.evaluate("() => window['result']").should eq("Clicked")
    end

    it "should work with node removed" do
      page.goto(server.prefix + "/input/button.html")
      page.evaluate("() => delete window['Node']")
      button = page.query_selector("button") || fail "button not found"
      button.click
      page.evaluate("() => window['result']").should eq("Clicked")
    end

    it "should work for shadow DOM V1" do
      page.goto(server.prefix + "/shadow.html")
      button = page.evaluate_handle("() => window['button']").as_element || fail "button not found"
      button.click
      page.evaluate("clicked").should be_true
    end

    it "should work for text nodes" do
      page.goto(server.prefix + "/input/button.html")
      button = page.evaluate_handle("() => document.querySelector('button').firstChild").as_element || fail "button not found"
      button.click
      page.evaluate("() => window['result']").should eq("Clicked")
    end

    it "should raise for detached nodes" do
      page.goto(server.prefix + "/input/button.html")
      button = page.query_selector("button") || fail "button not found"
      page.evaluate("button => button.remove()", button)
      expect_raises(PlaywrightException, "Element is not attached to the DOM") do
        button.click
      end
    end

    it "should raise for hidden nodes with force" do
      page.goto(server.prefix + "/input/button.html")
      button = page.query_selector("button") || fail "button not found"
      page.evaluate("button => button.style.display = 'none'", button)
      expect_raises(PlaywrightException, "Element is not visible") do
        button.click(ElementHandle::ClickOptions.new(force: true))
      end
    end

    it "should raise recursively for hidden nodes with force" do
      page.goto(server.prefix + "/input/button.html")
      button = page.query_selector("button") || fail "button not found"
      page.evaluate("button => button.parentElement.style.display = 'none'", button)
      expect_raises(PlaywrightException, "Element is not visible") do
        button.click(ElementHandle::ClickOptions.new(force: true))
      end
    end

    it "should raise for br elements with force" do
      page.set_content("hello<br>goodbye")
      br = page.query_selector("br") || fail "br not found"
      expect_raises(PlaywrightException, "Element is outside of the viewport") do
        br.click(ElementHandle::ClickOptions.new(force: true))
      end
    end

    it "should double click the button" do
      page.goto(server.prefix + "/input/button.html")
      page.evaluate(%(() => {
        window['double'] = false;
        const button = document.querySelector('button');
        button.addEventListener('dblclick', event => {
          window['double'] = true;
        });
      }))
      button = page.query_selector("button") || fail "button not found"
      button.dblclick
      page.evaluate("double").should be_true
      page.evaluate("result").should eq("Clicked")
    end
  end

  describe "ElementHandle::ContentFrame" do
    it "should work" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.empty_page)
      handle = page.query_selector("#frame1") || fail "frame not found"
      frame = handle.content_frame
      page.frames[1].should eq(frame)
    end

    it "should work for cross process iframes" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.cross_process_prefix + "/empty.html")
      handle = page.query_selector("#frame1") || fail "frame not found"
      frame = handle.content_frame
      page.frames[1].should eq(frame)
    end

    it "should work for cross frame evaluations" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.empty_page)
      frame = page.frames[1]
      handle = frame.evaluate_handle("() => window.top.document.querySelector('#frame1')").as_element || fail "unable to get handle to frame"
      frame.should eq(handle.content_frame)
    end

    it "should return nil for non iframes" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.empty_page)
      frame = page.frames[1]
      handle = frame.evaluate_handle("() => document.body").as_element || fail "unable to get handle to frame"
      handle.content_frame.should be_nil
    end

    it "should return nil for document documenElement" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.empty_page)
      frame = page.frames[1]
      handle = frame.evaluate_handle("() => document.documentElement").as_element || fail "unable to get handle to frame"
      handle.content_frame.should be_nil
    end
  end

  describe "ElementHandle::OwnerFrame" do
    it "should work" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.empty_page)
      frame = page.frames[1]
      handle = frame.evaluate_handle("() => document.body").as_element || fail "unable to get handle to frame"
      frame.should eq(handle.owner_frame)
    end

    it "should work for cross process iframes" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.cross_process_prefix + "/empty.html")
      frame = page.frames[1]
      handle = frame.evaluate_handle("() => document.body").as_element || fail "unable to get handle to frame"
      frame.should eq(handle.owner_frame)
    end

    it "should work for document" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.empty_page)
      frame = page.frames[1]
      handle = frame.evaluate_handle("() => document").as_element || fail "unable to get handle to frame"
      frame.should eq(handle.owner_frame)
    end

    it "should work for iframe elements" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.empty_page)
      frame = page.main_frame
      handle = frame.evaluate_handle("() => document.querySelector('#frame1')").as_element || fail "unable to get frame handle"
      frame.should eq(handle.owner_frame)
    end

    it "should work for cross frame evaluations" do
      page.goto(server.empty_page)
      attach_frame(page, "frame1", server.empty_page)
      frame = page.main_frame
      handle = frame.evaluate_handle("() => document.querySelector('iframe').contentWindow.document.body") || fail "unable to get handle to frame"
      frame.child_frames[0].should eq(handle.as_element.try &.owner_frame)
    end

    it "should work for detached elements" do
      page.goto(server.empty_page)
      handle = page.evaluate_handle(%(() => {
        const div = document.createElement('div');
        document.body.appendChild(div);
        return div;
      }))
      page.main_frame.should eq(handle.as_element.try &.owner_frame)
      page.evaluate(%(() => {
        const div = document.querySelector('div');
        document.body.removeChild(div);
      }))
      page.main_frame.should eq(handle.as_element.try &.owner_frame)
    end

    it "should work for adopted elements" do
      page.goto(server.empty_page)
      event = page.wait_for_event(Page::EventType::POPUP)
      page.evaluate("url => window['__popup'] = window.open(url)", server.empty_page)
      handle = page.evaluate_handle(%(() => {
        const div = document.createElement('div');
        document.body.appendChild(div);
        return div;
      }))
      page.main_frame.should eq(handle.as_element.try &.owner_frame)
      popup = event.get.data.as(Page)
      popup.wait_for_load_state(Page::LoadState::DOMCONTENTLOADED).get
      page.evaluate(%(() => {
        const div = document.querySelector('div');
        window['__popup'].document.body.appendChild(div);
      }))
      popup.main_frame.should eq(handle.as_element.try &.owner_frame)
    end
  end

  describe "ElementHandle::WaitForElementState" do
    it "should wait for visible" do
      page.set_content("<div style='display:none'>content</div>")
      div = page.query_selector("div") || fail "unable to get div element"
      promise = div.wait_for_element_state(ElementHandle::ElementState::VISIBLE)
      try_resolve(page)
      div.evaluate("div => div.style.display = 'block'")
      promise.get
    end

    it "should wait for already visible" do
      page.set_content("<div>content</div>")
      div = page.query_selector("div") || fail "unable to get div element"
      div.wait_for_element_state(ElementHandle::ElementState::VISIBLE)
    end

    it "should timeout waiting for visible" do
      page.set_content("<div style='display:none'>content</div>")
      div = page.query_selector("div") || fail "unable to get div element"
      result = div.wait_for_element_state(ElementHandle::ElementState::VISIBLE,
        ElementHandle::WaitForElementStateOptions.new(timeout: 1000))
      expect_raises(PlaywrightException, "Timeout 1000ms exceeded") do
        result.get
      end
    end

    it "should raise waiting for visible when detached" do
      page.set_content("<div style='display:none'>content</div>")
      div = page.query_selector("div") || fail "unable to get div element"
      result = div.wait_for_element_state(ElementHandle::ElementState::VISIBLE)
      div.evaluate("div => div.remove()")
      expect_raises(PlaywrightException, "Element is not attached to the DOM") do
        result.get
      end
    end

    it "should wait for hidden" do
      page.set_content("<div>content</div>")
      div = page.query_selector("div") || fail "unable to get div element"
      promise = div.wait_for_element_state(ElementHandle::ElementState::HIDDEN)
      try_resolve(page)
      div.evaluate("div => div.style.display = 'none'")
      promise.get
    end

    it "should wait for already hidden" do
      page.set_content("<div></div>")
      div = page.query_selector("div") || fail "unable to get div element"
      promise = div.wait_for_element_state(ElementHandle::ElementState::HIDDEN)
      promise.get
    end

    it "should wait for hidden when detached" do
      page.set_content("<div>content</div>")
      div = page.query_selector("div") || fail "unable to get div element"
      promise = div.wait_for_element_state(ElementHandle::ElementState::HIDDEN)
      try_resolve(page)
      div.evaluate("div => div.remove()")
      promise.get
    end

    it "should wait for enabled button" do
      page.set_content("<button disabled><span>Target</span></button>")
      span = page.query_selector("text=Target") || fail "unable to get button element"
      promise = span.wait_for_element_state(ElementHandle::ElementState::ENABLED)
      try_resolve(page)
      span.evaluate("span => span.parentElement.disabled = false")
      promise.get
    end

    it "should raise wait for enabled button when detached" do
      page.set_content("<button disabled>Target</button>")
      button = page.query_selector("button") || fail "unable to get button element"
      promise = button.wait_for_element_state(ElementHandle::ElementState::ENABLED)
      button.evaluate("button => button.remove()")
      expect_raises(PlaywrightException, "Element is not attached to the DOM") do
        promise.get
      end
    end

    it "should wait for disabled button" do
      page.set_content("<button><span>Target</span></button>")
      span = page.query_selector("text=Target") || fail "unable to get button element"
      promise = span.wait_for_element_state(ElementHandle::ElementState::DISABLED)
      try_resolve(page)
      span.evaluate("span => span.parentElement.disabled = true")
      promise.get
    end

    it "should wait for stable position" do
      {% if flag?(:linux) %}
        next if firefox?
      {% end %}
      page.goto(server.prefix + "/input/button.html")
      button = page.query_selector("button") || fail "unable to get button element"
      page.eval_on_selector("button", %(button => {
        button.style.transition = 'margin 10000ms linear 0s';
        button.style.marginLeft = '20000px';
      }))
      promise = button.wait_for_element_state(ElementHandle::ElementState::STABLE)
      try_resolve(page)
      button.evaluate("button => button.style.transition = ''")
      promise.get
    end
  end

  private def self.try_resolve(page)
    5.times do |_|
      page.evaluate(%(
        () => new Promise(f => requestAnimationFrame(() => requestAnimationFrame(f)))
      ))
    end
  end
end
