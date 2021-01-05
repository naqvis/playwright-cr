require "./spec_helper"

module Playwright
  it "test page workers" do
    worker_event = page.wait_for_event(Page::EventType::WORKER)
    page.goto(server.prefix + "/worker/worker.html")
    worker_event.get
    worker = page.workers[0]
    worker.url.includes?("worker.js").should be_true
    worker.evaluate("() => self['workerFunction']()").should eq("worker function result")
    page.goto(server.empty_page)
    page.workers.size.should eq(0)
  end

  it "should emit create and destroy events" do
    worker_promise = page.wait_for_event(Page::EventType::WORKER)
    worker_obj = page.evaluate_handle("() => new Worker(URL.createObjectURL(new Blob(['1'], {type: 'application/javascript'})))")
    worker = worker_promise.get.data.as(Worker)
    worker_this_obj = worker.evaluate_handle("() => this")
    worker_destroy_promise = worker.wait_for_event(Worker::EventType::CLOSE)
    page.evaluate("workerObj => workerObj.terminate()", worker_obj)
    worker_destroy_promise.get.data.should eq(worker)
    expect_raises(PlaywrightException, "Most likely the worker has been closed.") do
      worker_this_obj.get_property("self")
    end
  end

  it "should report console logs" do
    console_evt = page.wait_for_event(Page::EventType::CONSOLE)
    page.evaluate("() => new Worker(URL.createObjectURL(new Blob(['console.log(1)'], {type: 'application/javascript'})))")
    console_evt.get.data.as(ConsoleMessage).text.should eq("1")
  end

  it "should have JSHandle for Console Logs" do
    console_evt = page.wait_for_event(Page::EventType::CONSOLE)
    page.evaluate("() => new Worker(URL.createObjectURL(new Blob(['console.log(1,2,3,this)'], {type: 'application/javascript'})))")
    log = console_evt.get.data.as(ConsoleMessage)
    log.text.should eq("1 2 3 JSHandle@object")
    log.args.size.should eq(4)
    log.args[3].get_property("origin").json_value.should eq("null")
  end

  it "should evaluate" do
    promise = page.wait_for_event(Page::EventType::WORKER)
    page.evaluate("() => new Worker(URL.createObjectURL(new Blob(['console.log(1)'], {type: 'application/javascript'})))")
    worker = promise.get.data.as(Worker)
    worker.evaluate("1+1").should eq(2)
  end

  it "should report errors" do
    promise = page.wait_for_event(Page::EventType::PAGEERROR)
    page.evaluate(%(() => new Worker(URL.createObjectURL(new Blob([`
    setTimeout(() => {
      // Do a console.log just to check that we do not confuse it with an error.
        console.log('hey');
        throw new Error('this is my error');
      })
      `], {type: 'application/javascript'})))
    ))
    error_log = promise.get.data.as(Page::Error)
    error_log.message.includes?("this is my error").should be_true
  end

  it "should clear upon navigation" do
    next if firefox? # flaky upstream
    page.goto(server.empty_page)
    promise = page.wait_for_event(Page::EventType::WORKER)
    page.evaluate("() => new Worker(URL.createObjectURL(new Blob(['console.log(1)'], {type: 'application/javascript'})))")
    worker = promise.get.data.as(Worker)
    page.workers.size.should eq(1)
    destroyed = [false]
    worker.add_listener(Worker::EventType::CLOSE, ListenerImpl(Worker::EventType).new { |_| destroyed[0] = true })
    page.goto(server.prefix + "/one-style.html")
    destroyed[0].should be_true
    page.workers.size.should eq(0)
  end
end
