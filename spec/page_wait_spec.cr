require "uri"
require "./spec_helper"

module Playwright
  describe "Page Wait For Navigation" do
    it "should work" do
      page.goto(server.empty_page)
      resp = page.wait_for_navigation
      page.evaluate("url => window.location.href = url", server.prefix + "/grid.html")
      resp.get.try &.ok.should be_true || fail "unable to get response"
      resp.get.try &.url.includes?("grid.html").should be_true
    end

    it "should respect timeout" do
      promise = page.wait_for_navigation(Page::WaitForNavigationOptions.new(url: "**/frame.html", timeout: 5000))
      page.goto(server.empty_page)
      expect_raises(PlaywrightException, "Timeout 5000 ms exceeded") do
        promise.get
      end
    end

    it "should work with clicking on anchor links" do
      page.goto(server.empty_page)
      page.set_content("<a href='#foobar'>foobar</a>")
      resp = page.wait_for_navigation
      page.click("a")
      resp.get.should be_nil
      page.url.should eq(server.empty_page + "#foobar")
    end

    it "should work with DOM history back history forward" do
      page.goto(server.empty_page)
      page.set_content(%(
        <a id=back onclick='javascript:goBack()'>back</a>
        <a id=forward onclick='javascript:goForward()'>forward</a>
        <script>
          function goBack() { history.back(); }
          function goForward() { history.forward(); }
          history.pushState({}, '', '/first.html');
          history.pushState({}, '', '/second.html');
        </script>
      ))

      page.url.should eq(server.prefix + "/second.html")
      back_resp = page.wait_for_navigation
      page.click("a#back")
      back_resp.get.should be_nil
      page.url.should eq(server.prefix + "/first.html")

      forward_resp = page.wait_for_navigation
      page.click("a#forward")
      forward_resp.get.should be_nil
      page.url.should eq(server.prefix + "/second.html")
    end

    it "should work with url match" do
      page.goto(server.empty_page)

      resp1 = page.wait_for_navigation(Page::WaitForNavigationOptions.new(url: "**/one-style.html"))
      page.goto(server.prefix + "/one-style.html")

      resp1 = resp1.get || fail "unable to get response"
      resp1.url.should eq(server.prefix + "/one-style.html")

      resp2 = page.wait_for_navigation(Page::WaitForNavigationOptions.new(url: /frame.html$/))
      page.goto(server.prefix + "/frame.html")
      resp2 = resp2.get || fail "unable to get response"
      resp2.url.should eq(server.prefix + "/frame.html")

      resp3 = page.wait_for_navigation(Page::WaitForNavigationOptions.new(url: ->(url : String) {
        uri = URI.parse(url)
        if query = uri.query
          query.includes?("foo=bar")
        else
          false
        end
      }))
      page.goto(server.prefix + "/frame.html?foo=bar")
      resp3 = resp3.get || fail "unable to get response"
      resp3.url.should eq(server.prefix + "/frame.html?foo=bar")
    end
  end

  describe "Page Wait For Request" do
    it "should work" do
      page.goto(server.empty_page)
      request = page.wait_for_request(server.prefix + "/digits/2.png")
      page.evaluate(%(() => {
        fetch('/digits/1.png');
        fetch('/digits/2.png');
        fetch('/digits/3.png');
      }))

      request.get.not_nil!.url.should eq(server.prefix + "/digits/2.png")
    end

    it "should work with predicate" do
      page.goto(server.empty_page)
      request = page.wait_for_request(->(url : String) {
        url == (server.prefix + "/digits/2.png")
      })
      page.evaluate(%(() => {
        fetch('/digits/1.png');
        fetch('/digits/2.png');
        fetch('/digits/3.png');
      }))

      request.get.not_nil!.url.should eq(server.prefix + "/digits/2.png")
    end

    it "should respect timeout" do
      expect_raises(PlaywrightException, "Timeout 1 ms exceeded") do
        page.wait_for_event(Page::EventType::REQUEST, Page::WaitForEventOptions.new(
          predicate: ->(_u : Event(Page::EventType)) { false }, timeout: 1
        )).get
      end
    end

    it "should work with no timeout" do
      page.goto(server.empty_page)
      request = page.wait_for_request(server.prefix + "/digits/2.png", Page::WaitForRequestOptions.new(timeout: 0))
      page.evaluate(%(() => setTimeout(() => {
        fetch('/digits/1.png');
        fetch('/digits/2.png');
        fetch('/digits/3.png');
      },50)))
      request.get.not_nil!.url.should eq(server.prefix + "/digits/2.png")
    end
  end

  describe "Page Wait For Response" do
    it "should work" do
      page.goto(server.empty_page)
      response = page.wait_for_response(server.prefix + "/digits/2.png")
      page.evaluate(%(() => {
        fetch('/digits/1.png');
        fetch('/digits/2.png');
        fetch('/digits/3.png');
      }))

      response.get.not_nil!.url.should eq(server.prefix + "/digits/2.png")
    end

    it "should work with predicate" do
      page.goto(server.empty_page)
      response = page.wait_for_response(->(url : String) {
        url == (server.prefix + "/digits/2.png")
      })
      page.evaluate(%(() => {
        fetch('/digits/1.png');
        fetch('/digits/2.png');
        fetch('/digits/3.png');
      }))

      response.get.not_nil!.url.should eq(server.prefix + "/digits/2.png")
    end

    it "should respect timeout" do
      page.set_default_timeout(1)
      expect_raises(PlaywrightException, "Timeout 1 ms exceeded") do
        page.wait_for_event(Page::EventType::RESPONSE, ->(_u : Event(Page::EventType)) { false }).get
      end
    end

    it "should work with no timeout" do
      page.goto(server.empty_page)
      response = page.wait_for_response(server.prefix + "/digits/2.png", Page::WaitForResponseOptions.new(timeout: 0))
      page.evaluate(%(() => setTimeout(() => {
        fetch('/digits/1.png');
        fetch('/digits/2.png');
        fetch('/digits/3.png');
      },50)))
      response.get.not_nil!.url.should eq(server.prefix + "/digits/2.png")
    end
  end
end
