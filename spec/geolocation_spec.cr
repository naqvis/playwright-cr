require "./spec_helper"

module Playwright
  it "should work" do
    context.grant_permissions(["geolocation"])
    page.goto(server.empty_page)
    context.set_geolocation(Geolocation.new(10, 10))
    location = page.evaluate(%(
      () => new Promise(resolve => navigator.geolocation.getCurrentPosition(position => {
        resolve({latitude: position.coords.latitude, longitude: position.coords.longitude});
        }))
    ))
    location.should eq({"latitude" => 10, "longitude" => 10})
  end

  it "should raise when invalid longitude" do
    expect_raises(PlaywrightException, "geolocation.longitude: precondition -180 <= LONGITUDE <= 180 failed.") do
      context.set_geolocation(Geolocation.new(10, 200))
    end
  end

  it "should isolate contexts" do
    context.grant_permissions(["geolocation"])
    context.set_geolocation(Geolocation.new(10, 10))
    page.goto(server.empty_page)

    context2 = browser.new_context(Browser::NewContextOptions.new(
      permissions: ["geolocation"],
      geolocation: Geolocation.new(20, 20)
    ))
    page2 = context2.new_page
    page2.goto(server.empty_page)

    location = page.evaluate(%(
      () => new Promise(resolve => navigator.geolocation.getCurrentPosition(position => {
        resolve({latitude: position.coords.latitude, longitude: position.coords.longitude});
        }))
    ))
    location.should eq({"latitude" => 10, "longitude" => 10})

    location2 = page2.evaluate(%(
      () => new Promise(resolve => navigator.geolocation.getCurrentPosition(position => {
        resolve({latitude: position.coords.latitude, longitude: position.coords.longitude});
        }))
    ))
    location2.should eq({"latitude" => 20, "longitude" => 20})
  end

  it "should not modify passed default options object" do
    geo = Geolocation.new(10, 10)
    options = Browser::NewContextOptions.new(geolocation: geo)
    context = browser.new_context(options)
    context.set_geolocation(Geolocation.new(20, 20))
    geo.should eq(options.geolocation)
    context.close
  end

  it "should notify watch position" do
    context.grant_permissions(["geolocation"])
    page.goto(server.empty_page)
    messages = [] of String
    page.add_listener(Page::EventType::CONSOLE, ListenerImpl(Page::EventType).new { |event|
      messages << event.data.as(ConsoleMessage).text
    })
    context.set_geolocation(Geolocation.new)
    page.evaluate(%(() => {
    navigator.geolocation.watchPosition(pos => {
      const coords = pos.coords;
      console.log(`lat=${coords.latitude} lng=${coords.longitude}`);
      }, err => {});
  }))
    begin
      deferred = page.wait_for_event(Page::EventType::CONSOLE, ->(event : Event(Page::EventType)) {
        event.data.as(ConsoleMessage).text.includes?("lat=0 lng=10")
      })
      context.set_geolocation(Geolocation.new(0, 10))
      deferred.get
    end
    begin
      deferred = page.wait_for_event(Page::EventType::CONSOLE, ->(event : Event(Page::EventType)) {
        event.data.as(ConsoleMessage).text.includes?("lat=20 lng=30")
      })
      context.set_geolocation(Geolocation.new(20, 30))
      deferred.get
    end
    begin
      deferred = page.wait_for_event(Page::EventType::CONSOLE, ->(event : Event(Page::EventType)) {
        event.data.as(ConsoleMessage).text.includes?("lat=40 lng=50")
      })
      context.set_geolocation(Geolocation.new(40, 50))
      deferred.get
    end

    messages.includes?("lat=0 lng=10").should be_true
    messages.includes?("lat=20 lng=30").should be_true
    messages.includes?("lat=40 lng=50").should be_true
  end

  it "should use context options for popup" do
    context.grant_permissions(["geolocation"])
    context.set_geolocation(Geolocation.new(10, 10))
    popup_evt = page.wait_for_event(Page::EventType::POPUP)
    page.evaluate("url => window['_popup'] = window.open(url)", server.prefix + "/geolocation.html")
    popup = popup_evt.get.data.as(Page)
    popup.wait_for_load_state
    geo = popup.evaluate("window['geolocationPromise']")
    geo.should eq({"latitude" => 10, "longitude" => 10})
  end
end
