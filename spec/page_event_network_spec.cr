require "./spec_helper"

module Playwright
  it "test page events request" do
    requests = [] of Request
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |evt|
      requests << evt.data.as(Request)
    })
    page.goto(server.empty_page)
    requests.size.should eq(1)
    requests[0].url.should eq(server.empty_page)
    requests[0].resource_type.should eq("document")
    requests[0].method.should eq("GET")
    requests[0].response.should_not be_nil
    requests[0].frame.should eq(page.main_frame)
    requests[0].frame.url.should eq(server.empty_page)
  end

  it "test page events response" do
    responses = [] of Response
    page.add_listener(Page::EventType::RESPONSE, ListenerImpl(Page::EventType).new { |evt|
      responses << evt.data.as(Response)
    })
    page.goto(server.empty_page)
    responses.size.should eq(1)
    responses[0].url.should eq(server.empty_page)
    responses[0].status.should eq(200)
    responses[0].ok.should be_true
    responses[0].request.should_not be_nil
  end

  it "should fire events in proper order" do
    events = [] of String
    page.add_listener(Page::EventType::REQUEST, ListenerImpl(Page::EventType).new { |_| events << "request" })
    page.add_listener(Page::EventType::RESPONSE, ListenerImpl(Page::EventType).new { |_| events << "response" })
    page.goto(server.empty_page) || fail "no response returned"
    events << "requestfinished"
    events.should eq(["request", "response", "requestfinished"])
  end

  it "test screenshot" do
    page.set_viewport_size(500, 500)
    page.goto(server.prefix + "/grid.html")
    screenshot = page.screenshot
    screenshot.size.should be > 0
  end

  it "test screenshot clip rect" do
    page.set_viewport_size(500, 500)
    page.goto(server.prefix + "/grid.html")
    screenshot = page.screenshot(Page::ScreenshotOptions.new(clip: Page::ScreenshotOptions::Clip.new(x: 50, y: 100, width: 150, height: 100)))
    screenshot.size.should be > 0
  end

  it "should select single option" do
    page.goto(server.prefix + "/input/select.html")
    page.select_option("select", "blue")
    page.evaluate("() => window['result'].onInput").should eq(["blue"])
    page.evaluate("() => window['result'].onChange").should eq(["blue"])
  end

  it "should select option by value" do
    page.goto(server.prefix + "/input/select.html")
    page.select_option("select", ElementHandle::SelectOption.new(value: "blue"))
    page.evaluate("() => window['result'].onInput").should eq(["blue"])
    page.evaluate("() => window['result'].onChange").should eq(["blue"])
  end

  it "should select option by label" do
    page.goto(server.prefix + "/input/select.html")
    page.select_option("select", ElementHandle::SelectOption.new(label: "Indigo"))
    page.evaluate("() => window['result'].onInput").should eq(["indigo"])
    page.evaluate("() => window['result'].onChange").should eq(["indigo"])
  end

  it "should select option by handle" do
    page.goto(server.prefix + "/input/select.html")
    page.select_option("select", page.query_selector("[id=whiteOption]"))
    page.evaluate("() => window['result'].onInput").should eq(["white"])
    page.evaluate("() => window['result'].onChange").should eq(["white"])
  end

  it "should select single option by index" do
    page.goto(server.prefix + "/input/select.html")
    page.select_option("select", ElementHandle::SelectOption.new(index: 2))
    page.evaluate("() => window['result'].onInput").should eq(["brown"])
    page.evaluate("() => window['result'].onChange").should eq(["brown"])
  end

  it "should select single option by multiple attributes" do
    page.goto(server.prefix + "/input/select.html")
    page.select_option("select", ElementHandle::SelectOption.new(value: "green", label: "Green"))
    page.evaluate("() => window['result'].onInput").should eq(["green"])
    page.evaluate("() => window['result'].onChange").should eq(["green"])
  end

  it "should select only first option" do
    page.goto(server.prefix + "/input/select.html")
    page.select_option("select", ["blue", "green", "red"])
    page.evaluate("() => window['result'].onInput").should eq(["blue"])
    page.evaluate("() => window['result'].onChange").should eq(["blue"])
  end

  it "should not raise when select cause navigation" do
    page.goto(server.prefix + "/input/select.html")
    page.eval_on_selector("select", "select => select.addEventListener('input', () => window.location.href = '/empty.html')")
    resp = page.wait_for_navigation
    page.select_option("select", "blue")
    resp.get
    page.url.includes?("empty.html").should be_true
  end

  it "should select multiple options" do
    page.goto(server.prefix + "/input/select.html")
    page.evaluate("() => window['makeMultiple']()")
    page.select_option("select", ["blue", "green", "red"])
    page.evaluate("() => window['result'].onInput").should eq(["blue", "green", "red"])
    page.evaluate("() => window['result'].onChange").should eq(["blue", "green", "red"])
  end

  it "should select multiple options with attributes" do
    page.goto(server.prefix + "/input/select.html")
    page.evaluate("() => window['makeMultiple']()")
    page.select_option("select", [
      ElementHandle::SelectOption.new(value: "blue"),
      ElementHandle::SelectOption.new(label: "Green"),
      ElementHandle::SelectOption.new(index: 4),
    ])
    page.evaluate("() => window['result'].onInput").should eq(["blue", "gray", "green"])
    page.evaluate("() => window['result'].onChange").should eq(["blue", "gray", "green"])
  end

  it "should raise when element is not select" do
    page.goto(server.prefix + "/input/select.html")
    expect_raises(PlaywrightException, "Element is not a <select> element.") do
      page.select_option("body", "")
    end
  end

  it "should return on no match value" do
    page.goto(server.prefix + "/input/select.html")
    result = page.select_option("select", ["42", "abc"])
    result.should eq([] of String)
  end

  it "should return an array of matched values" do
    page.goto(server.prefix + "/input/select.html")
    page.evaluate("() => window['makeMultiple']()")
    result = page.select_option("select", ["blue", "black", "magenta"])
    result = result.sort
    expected = ["blue", "black", "magenta"].sort
    result.should eq(expected)
  end

  it "test page extra http headers" do
    headers = HTTP::Headers.new
    server.add_handler("/empty.html") { |context|
      headers = context.request.headers
    }
    page.set_extra_http_headers({"foo" => "bar"})
    page.goto(server.prefix + "/empty.html")
    headers["foo"].should eq("bar")
  end

  it "should upload the file" do
    page.goto(server.prefix + "/input/fileupload.html")
    input = page.query_selector("input") || fail "unable to get input handler"
    input.set_input_files(FILE_TO_UPLOAD)
    page.evaluate("e => e.files[0].name", input).should eq("file-to-upload.txt")
    page.evaluate(%(e => {
    const reader = new FileReader();
    const promise = new Promise(fulfill => reader.onload = fulfill);
    reader.readAsText(e.files[0]);
    return promise.then(() => reader.result);
  }), input).should eq("contents of the file")
  end

  it "should upload file from memory" do
    page.set_content("<input type=file>")
    page.set_input_files("input", FileChooser::FilePayload.new(name: "test.txt", mime_type: "text/plain", buffer: "this is a test".to_slice))
    page.eval_on_selector("input", "input => input.files.length").should eq(1)
    page.eval_on_selector("input", "input => input.files[0].name").should eq("test.txt")
  end

  it "should emit event once" do
    page.set_content("<input type=file>")
    event = page.wait_for_event(Page::EventType::FILECHOOSER)
    page.click("input")
    event.get.data.as?(FileChooser) || fail "unable to get chooser instance"
  end

  it "should emit event, add listener, remove listener" do
    page.set_content("<input type=file>")
    chooser = [] of FileChooser
    page.add_listener(Page::EventType::FILECHOOSER, ListenerImpl(Page::EventType).new { |evt|
      chooser << evt.data.as(FileChooser)
    })
    page.click("input")
    start = Time.monotonic
    while (chooser.empty? && (Time.monotonic - start) < 10_000.milliseconds)
      page.wait_for_timeout(100).get
    end
    chooser.size.should be > 0
    chooser[0].should_not be_nil
  end

  it "should respect timeout" do
    expect_raises(PlaywrightException, "Timeout 1 ms exceeded") do
      event = page.wait_for_event(Page::EventType::FILECHOOSER, Page::WaitForEventOptions.new(timeout: 1))
      event.get
    end
  end

  it "should be able to read selected file" do
    page.set_content("<input type=file>")
    page.add_listener(Page::EventType::FILECHOOSER, ListenerImpl(Page::EventType).new { |evt|
      chooser = evt.data.as(FileChooser)
      chooser.set_files(FILE_TO_UPLOAD)
    })

    content = page.eval_on_selector("input", %(async picker => {
      picker.click();
      await new Promise(x => picker.oninput = x);
      const reader = new FileReader();
      const promise = new Promise(fulfill => reader.onload = fulfill);
      reader.readAsText(picker.files[0]);
      return promise.then(() => reader.result);
    }))
    content.should eq("contents of the file")
  end

  it "should not accept multiple files for single file input" do
    page.set_content("<input type=file>")
    event = page.wait_for_event(Page::EventType::FILECHOOSER)
    page.click("input")
    chooser = event.get.data.as?(FileChooser) || fail "Unable to get filechooser handle"
    expect_raises(PlaywrightException, "Non-multiple file input can only accept single file") do
      chooser.set_files([FILE_TO_UPLOAD, Path["#{RESOURCE_DIR}/pptr.png"]])
    end
  end

  it "should work for multiple" do
    page.set_content("<input multiple type=file>")
    event = page.wait_for_event(Page::EventType::FILECHOOSER)
    page.click("input")
    chooser = event.get.data.as?(FileChooser) || fail "Unable to get filechooser handle"
    chooser.is_multiple.should be_true
  end

  it "should work for webkit directory" do
    page.set_content("<input multiple webkitdirectory type=file>")
    event = page.wait_for_event(Page::EventType::FILECHOOSER)
    page.click("input")
    chooser = event.get.data.as?(FileChooser) || fail "Unable to get filechooser handle"
    chooser.is_multiple.should be_true
  end
end
