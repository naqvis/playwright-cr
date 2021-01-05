require "./spec_helper"

module Playwright
  it "should work for main frame navigation request" do
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      requests << event.data.as(Request)
    })
    page.goto(server.empty_page)
    requests.size.should eq(1)
    page.main_frame.should eq(requests[0].frame)
  end

  it "should work for subframe navigation request" do
    page.goto(server.empty_page)
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      requests << event.data.as(Request)
    })
    attach_frame(page, "frame1", server.empty_page)
    requests.size.should eq(1)
    page.frames[1].should eq(requests[0].frame)
  end

  it "should work for fetch requests" do
    page.goto(server.empty_page)
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      requests << event.data.as(Request)
    })
    page.evaluate("() => fetch('/digits/1.png')")
    requests.size.should eq(1)
    page.main_frame.should eq(requests[0].frame)
  end

  it "should work for a redirect" do
    server.add_handler("/foo.html") { |context|
      context.response.headers["location"] = "/empty.html"
      context.response.status_code = 302
    }
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      requests << event.data.as(Request)
    })
    page.goto(server.prefix + "/foo.html")
    requests.size.should eq(2)
    requests[0].url.should eq(server.prefix + "/foo.html")
    requests[1].url.should eq(server.prefix + "/empty.html")
  end

  it "should not work for a redirect and interception" do
    # https://github.com/microsoft/playwright/issues/3993
    server.add_handler("/foo.html") { |context|
      context.response.headers["location"] = "/empty.html"
      context.response.status_code = 302
    }
    requests = [] of Request
    page.route("**", Consumer(Route).new { |route|
      requests << route.request
      route.continue
    })
    page.goto(server.prefix + "/foo.html")
    page.url.should eq(server.prefix + "/empty.html")
    requests.size.should eq(1)
    requests[0].url.should eq(server.prefix + "/foo.html")
  end

  it "should return headers" do
    response = page.goto(server.empty_page) || fail "unable to get response"
    if chromium?
      response.request.headers["user-agent"].includes?("Chrome").should be_true
    elsif firefox?
      response.request.headers["user-agent"].includes?("Firefox").should be_true
    elsif webkit?
      response.request.headers["user-agent"].includes?("WebKit").should be_true
    else
      fail "Uknown browser"
    end
  end

  it "should return post data" do
    page.goto(server.empty_page)
    server.add_handler("/post") { |context|
      context.response.status_code = 200
    }
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      requests << event.data.as(Request)
    })
    page.evaluate("() => fetch('./post', { method: 'POST', body: JSON.stringify({foo: 'bar'})})")
    requests.size.should eq(1)
    requests[0].post_data.should eq(%({"foo":"bar"}))
  end

  it "should work with binary post_data" do
    page.goto(server.empty_page)
    server.add_handler("/post") { |context|
      context.response.status_code = 200
    }
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      requests << event.data.as(Request)
    })
    page.evaluate(%(async () => {
      await fetch('./post', { method: 'POST', body: new Uint8Array(Array.from(Array(256).keys())) });
    }))
    requests.size.should eq(1)
    buffer = requests[0].post_data_buffer || "post data is nil"
    buffer.size.should eq(256)
    0.upto(255) do |i|
      buffer[i].should eq(i.to_u8)
    end
  end

  it "should work with binary post_data and interception" do
    page.goto(server.empty_page)
    server.add_handler("/post") { |context|
      context.response.status_code = 200
    }
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      requests << event.data.as(Request)
    })

    page.route("/post", Consumer(Route).new { |route| route.continue })
    page.evaluate(%(async () => {
      await fetch('./post', { method: 'POST', body: new Uint8Array(Array.from(Array(256).keys())) });
    }))
    requests.size.should eq(1)
    buffer = requests[0].post_data_buffer || "post data is nil"
    buffer.size.should eq(256)
    0.upto(255) do |i|
      buffer[i].should eq(i.to_u8)
    end
  end

  it "should be undefined when there is no post_data" do
    response = page.goto(server.empty_page) || fail "unable to get response"
    response.request.post_data.should be_nil
  end

  it "should return event source" do
    # Setup server-sent events on server that immediately sends a message to the client.
    server.add_handler("/sse") { |context|
      context.response.content_type = "text/event-stream"
      context.response.headers["Connection"] = "keep-alive"
      context.response.headers["Cache-Control"] = "no-cache"
      context.response.status_code = 200
      context.response.puts %(data: {"foo":"bar"})
      context.response.puts "\n\n"
    }

    # subscribe o page request events
    page.goto(server.empty_page)
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      requests << event.data.as(Request)
    })
    # connect to EventSource in browser and return first message.
    result = page.evaluate(%(() => {
      const eventSource = new EventSource('/sse');
      return new Promise(resolve => {
        eventSource.onmessage = e => resolve(JSON.parse(e.data));
      });
    }))
    result.should eq({"foo" => "bar"})
    requests[0].resource_type.should eq("eventsource")
  end

  it "should return navigation bit" do
    requests = {} of String => Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      request = event.data.as(Request)
      name = request.url
      last_slash = last_index_of(name, '/')
      name = name[last_slash.not_nil! + 1..] if last_slash
      requests[name] = request
    })

    server.add_handler("/rrredirect") { |context|
      context.response.headers["location"] = "/frames/one-frame.html"
      context.response.status_code = 302
    }
    page.goto(server.prefix + "/rrredirect")

    requests["rrredirect"].is_navigation_request.should be_true
    requests["one-frame.html"].is_navigation_request.should be_true
    requests["frame.html"].is_navigation_request.should be_true
    requests["script.js"].is_navigation_request.should be_false
    requests["style.css"].is_navigation_request.should be_false
  end

  it "should return navigation bit when navigating to image" do
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |event|
      requests << event.data.as(Request)
    })
    page.goto(server.prefix + "/pptr.png")
    requests[0].is_navigation_request.should be_true
  end

  it "should amend method" do
    server.add_handler("/sleep.zzz") { |context|
      context.request.method.should eq("POST")
    }

    page.goto(server.empty_page)
    page.route("**/*", Consumer(Route).new { |route| route.continue(Route::ContinueOverrides.new(method: "POST")) })
    page.evaluate("() => fetch('/sleep.zzz')")
  end

  it "should not allow changing protocol when overriding url" do
    errors = [] of Exception
    page.route("**/*", Consumer(Route).new { |route|
      begin
        route.continue(Route::ContinueOverrides.new(url: "file:///tmp/foo"))
      rescue ex
        errors << ex
        route.continue
      end
    })

    page.goto(server.empty_page)
    errors.size.should be > 0
    errors[0].should_not be_nil
    errors[0].message.not_nil!.includes?("New URL must have same protocol as overriden URL").should be_true
  end

  it "test request fulfill" do
    page.route("**/*", Consumer(Route).new { |route|
      route.fulfill(Route::FulfillResponse.new(status: 201, content_type: "text/html",
        headers: {"foo" => "bar"}, body: "Yo, page!"))
    })

    resp = page.goto(server.empty_page) || fail "unable to get response"
    resp.status.should eq(201)
    resp.headers["foo"].should eq("bar")
    page.evaluate("() => document.body.textContent").should eq("Yo, page!")
  end

  def self.last_index_of(str, needle)
    idx = -1
    while v = str.index(needle, idx + 1)
      idx = v
    end
    idx == -1 ? nil : idx
  end
end
