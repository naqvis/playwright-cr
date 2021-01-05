require "./spec_helper"

module Playwright
  it "should work" do
    server.add_handler("/empty.html") { |context|
      context.response.headers["foo"] = "bar"
      context.response.headers["BaZ"] = "bAz"
      context.response.status_code = 200
    }
    resp = page.goto(server.empty_page) || fail "unable to get response"
    resp.headers["foo"].should eq("bar")
    resp.headers["baz"].should eq("bAz")
    resp.headers["BaZ"]?.should be_nil
  end

  it "should return text" do
    resp = page.goto(server.prefix + "/simple.json") || fail "unable to get response"
    resp.text.should eq(%({"foo": "bar"}\n))
  end

  it "should raise when requesting body of redirected response" do
    server.add_handler("/foo.html") { |context|
      context.response.headers["location"] = "/empty.html"
      context.response.status_code = 302
    }
    resp = page.goto(server.prefix + "/foo.html") || fail "unable to get response"
    redirected_from = resp.request.redirected_from || fail "redirected_from is nil"
    redirected = redirected_from.response || fail "redirected_from.response is nil"
    redirected.status.should eq(302)
    expect_raises(PlaywrightException, "Response body is unavailable for redirect responses") do
      redirected.text
    end
  end

  it "should wait until response completes" do
    page.goto(server.empty_page)

    server.add_handler("/get") { |context|
      # In Firefox, |fetch| will be hanging until it receives |Content-Type| header from server
      context.response.content_type = "text/plain; charset=utf-8"
      context.response.status_code = 200
      context.response << "hello "
      context.response.flush
      context.response << "wor"
      context.response.flush
      context.response << "ld!"
    }

    # setup page to trap response
    request_finished = [false]
    page.add_listener(Page::EventType::REQUESTFINISHED, ListenerImpl(Page::EventType).new { |event|
      request_finished[0] |= event.data.as(Request).url.includes?("/get")
    })

    # send request and wait for server response
    resp_event = page.wait_for_event(Page::EventType::RESPONSE)
    page.evaluate("() => fetch('./get', { method: 'GET'})")
    resp_event.get || fail "unable to get response event"
    page_resp = resp_event.get.data.as?(Response) || fail "unable to get response data"
    page_resp.status.should eq(200)
    # request_finished[0].should be_false
    page_resp.text.should eq("hello world!")
    request_finished[0].should be_true
  end

  it "should return body" do
    resp = page.goto(server.prefix + "/pptr.png") || fail "unable to get response"
    expected = File.read("spec/resources/pptr.png")
    resp.body.should eq(expected.to_slice)
  end

  it "should return status text" do
    server.add_handler("/cool") { |context|
      context.response.status_code = 200
    }
    resp = page.goto(server.prefix + "/cool") || fail "unable to get response"
    resp.status_text.should eq("OK")
  end
end
