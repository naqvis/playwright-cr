require "./spec_helper"

module Playwright
  it "should time out" do
    start = Time.monotonic
    timeout = 42
    page.wait_for_timeout(timeout).get
    (Time.monotonic - start).milliseconds.should be > (timeout // 2)
  end

  it "should accept a string" do
    watchdog = page.wait_for_function("window.__FOO === 1")
    page.evaluate("() => window['__FOO'] = 1")
    watchdog.get
  end

  it "should work when resolved right before execution context disposal" do
    page.add_init_script("window['__RELOADED'] = true")
    page.wait_for_function(%(() => {
      if (!window['__RELOADED'])
        window.location.reload();
      return true;
    })).get
  end

  it "should poll on interval" do
    polling = 100
    time_delta = page.wait_for_function(%(() => {
      if (!window["__startTime"]) {
        window["__startTime"] = Date.now();
        return false;
      }
      return Date.now() - window["__startTime"];
    }), nil, Page::WaitForFunctionOptions.new(polling: polling))
    delta = time_delta.get.evaluate("h => h").as_i
    delta.should be >= polling
  end

  it "should avoid side effects after timeout" do
    counter = [0]
    page.add_listener(Page::EventType::CONSOLE, ListenerImpl(Page::EventType).new { |_| counter[0] += 1 })

    result = page.wait_for_function(%(() => {
      window['counter'] = (window['counter'] || 0) + 1;
      console.log(window['counter']);
    }), nil, Page::WaitForFunctionOptions.new(timeout: 1000))

    expect_raises(PlaywrightException, "Timeout 1000ms exceeded") do
      result.get
    end

    saved_counter = counter[0]
    page.wait_for_timeout(2000) # give it some time to produce more logs
    saved_counter.should eq(counter[0])
  end

  it "should poll on Raf" do
    watchdog = page.wait_for_function("() => window['__FOO'] === 'hit'", nil,
      Page::WaitForFunctionOptions.new.with_request_animation_frame)
    page.evaluate("() => window['__FOO'] = 'hit'")
    watchdog.get
  end

  it "should fail with predicate throwing on first call" do
    expect_raises(PlaywrightException, "oh my") do
      page.wait_for_function("() => { throw new Error('oh my'); }").get
    end
  end

  it "should fail with predicate throwing on sometimes" do
    expect_raises(PlaywrightException, "Bad counter!") do
      page.wait_for_function(%(() => {
        window['counter'] = (window['counter'] || 0) + 1;
        if (window['counter'] === 3)
          throw new Error('Bad counter!');
        return window['counter'] === 5 ? 'result' : false;
      })).get
    end
  end

  it "should raise negative polling interval" do
    expect_raises(PlaywrightException, "Cannot poll with non-positive interval") do
      page.wait_for_function("() => !!document.body", nil, Page::WaitForFunctionOptions.new(polling: -10)).get
    end
  end

  it "should return the success value as a JSHandle" do
    page.wait_for_function("5").get.json_value.should eq(5)
  end

  it "should respect default timeout" do
    page.set_default_timeout(1)
    expect_raises(PlaywrightException, "Timeout 1ms exceeded") do
      page.wait_for_function("false").get
    end
  end
end
