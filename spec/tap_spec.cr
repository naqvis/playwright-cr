require "./spec_helper"

module Playwright
  def self.create_context
    browser.not_nil!.new_context(Browser::NewContextOptions.new(has_touch: true))
  end

  private def self.track_events(target : ElementHandle)
    target.evaluate_handle(%(target => {
      const events = [];
      for (const event of [
        'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseout', 'mouseover', 'mouseup', 'click',
        'pointercancel', 'pointerdown', 'pointerenter', 'pointerleave', 'pointermove', 'pointerout', 'pointerover', 'pointerup',
        'touchstart', 'touchend', 'touchmove', 'touchcancel'])
        target.addEventListener(event, () => events.push(event), false);
      return events;
    }))
  end

  it "should send all of the correct events" do
    page.set_content(%(
      <div id='a' style='background: lightblue; width: 50px; height: 50px'>a</div>
      <div id='b' style='background: pink; width: 50px; height: 50px'>b</div>
    ))

    page.tap("#a")
    selector = page.query_selector("#b") || fail "unable to find selector"
    events = track_events(selector)
    page.tap("#b")

    # Webkit doesn't end pointerenter or pointerleave or mouseout
    events.json_value.should eq([
      "pointerover", "pointerenter",
      "pointerdown", "touchstart",
      "pointerup", "pointerout",
      "pointerleave", "touchend",
      "mouseover", "mouseenter",
      "mousemove", "mousedown",
      "mouseup", "click",
    ])
  end

  it "should not send mouse events touch start is cancelled" do
    page.set_content("<div style='width: 50px; height: 50px; background: red'>")
    page.evaluate(%(() => {
      // touchstart is not cancelable unless passive is false
      document.addEventListener('touchstart', t => t.preventDefault(), {passive: false});
    }))

    events = track_events(page.query_selector("div") || fail "unable to find div")
    page.tap("div")
    events.json_value.should eq([
      "pointerover", "pointerenter",
      "pointerdown", "touchstart",
      "pointerup", "pointerout",
      "pointerleave", "touchend",
    ])
  end

  it "should not send mouse events when touch end is cancelled" do
    page.set_content("<div style='width: 50px; height: 50px; background: red'>")
    page.evaluate(%(() => document.addEventListener('touchend', t => t.preventDefault())))

    events = track_events(page.query_selector("div") || fail "unable to find div")
    page.tap("div")
    events.json_value.should eq([
      "pointerover", "pointerenter",
      "pointerdown", "touchstart",
      "pointerup", "pointerout",
      "pointerleave", "touchend",
    ])
  end

  it "should work with tap modifiers" do
    page.set_content("hello world")
    page.evaluate(%(() => {
        window.touchPromise = new Promise(resolve => {
          document.addEventListener('touchstart', event => {
            resolve(event.altKey);
          }, {passive: false});
        });
      }))

    page.tap("body", Page::TapOptions.new(modifiers: Set{Keyboard::Modifier::ALT}))
    page.evaluate("() => window.touchPromise").should be_true
  end

  it "should send well formed touch points" do
    page.evaluate(%(() => {
        window.touchStartPromise = new Promise(resolve => {
            document.addEventListener('touchstart', event => {
              resolve([...event.touches].map(t => ({
                identifier: t.identifier,
                clientX: t.clientX,
                clientY: t.clientY,
                pageX: t.pageX,
                pageY: t.pageY,
                radiusX: 'radiusX' in t ? t.radiusX : t['webkitRadiusX'],
                radiusY: 'radiusY' in t ? t.radiusY : t['webkitRadiusY'],
                rotationAngle: 'rotationAngle' in t ? t.rotationAngle : t['webkitRotationAngle'],
                force: 'force' in t ? t.force : t['webkitForce'],
              })));
            }, false);
          })
    }))

    page.evaluate(%(() => {
      window.touchEndPromise = new Promise(resolve => {
        document.addEventListener('touchend', event => {
          resolve([...event.touches].map(t => ({
            identifier: t.identifier,
            clientX: t.clientX,
            clientY: t.clientY,
            pageX: t.pageX,
            pageY: t.pageY,
            radiusX: 'radiusX' in t ? t.radiusX : t['webkitRadiusX'],
            radiusY: 'radiusY' in t ? t.radiusY : t['webkitRadiusY'],
            rotationAngle: 'rotationAngle' in t ? t.rotationAngle : t['webkitRotationAngle'],
            force: 'force' in t ? t.force : t['webkitForce'],
          })));
        }, false);
      })
    }))

    page.touchscreen.tap(40, 60)
    touch_start = page.evaluate("() => window.touchStartPromise") || fail "unable to evaluate"
    touch_start.should eq([{
      "identifier"    => 0,
      "clientX"       => 40,
      "clientY"       => 60,
      "pageX"         => 40,
      "pageY"         => 60,
      "radiusX"       => 1,
      "radiusY"       => 1,
      "rotationAngle" => 0,
      "force"         => 1,
    }])
    touch_end = page.evaluate("() => window.touchEndPromise") || fail "unable to evaluate"
    touch_end.should eq([] of String)
  end
end
