require "./spec_helper"

module Playwright
  describe "Dispatch" do
    it "should dispatch click event" do
      page.goto(server.prefix + "/input/button.html")
      page.dispatch_event("button", "click")
      page.evaluate("() => window['result']").should eq("Clicked")
    end

    it "should dispatch click event properties" do
      page.goto(server.prefix + "/input/button.html")
      page.dispatch_event("button", "click")
      page.evaluate("bubbles").should_not be_nil
      page.evaluate("cancelable").should_not be_nil
      page.evaluate("composed").should_not be_nil
    end

    it "should dispatch click svg" do
      page.set_content(%(
        <svg height='100' width='100'>
        <circle onclick='javascript:window.__CLICKED=42' cx='50' cy='50' r='40' stroke='black' stroke-width='3' fill='red' />
        </svg>
      ))

      page.dispatch_event("circle", "click")
      page.evaluate("() => window['__CLICKED']").should eq(42)
    end

    it "should dispatch click on a span with an inline element inside" do
      page.set_content(%(
        <style>
          span::before {
            content: 'q';
          }
        </style>
        <span onclick='javascript:window.CLICKED=42'></span>
      ))

      page.dispatch_event("span", "click")
      page.evaluate("() => window['CLICKED']").should eq(42)
    end

    it "should dispatch click after navigation" do
      page.goto(server.prefix + "/input/button.html")
      page.dispatch_event("button", "click")
      page.goto(server.prefix + "/input/button.html")
      page.dispatch_event("button", "click")
      page.evaluate("() => window['result']").should eq("Clicked")
    end

    it "should dispatch click after cross origin navigation" do
      page.goto(server.prefix + "/input/button.html")
      page.dispatch_event("button", "click")
      page.goto(server.cross_process_prefix + "/input/button.html")
      page.dispatch_event("button", "click")
      page.evaluate("() => window['result']").should eq("Clicked")
    end

    it "should not fail when element is blocked on hover" do
      page.set_content(%(
        <style>
          container { display: block; position: relative; width: 200px; height: 50px; }
          div, button { position: absolute; left: 0; top: 0; bottom: 0; right: 0; }
          div { pointer-events: none; }
          container:hover div { pointer-events: auto; background: red; }
        </style>
        <container>
          <button onclick='window.clicked=true'>Click me</button>
          <div></div>
        </container>
      ))
      page.dispatch_event("button", "click")
      page.evaluate("() => window['clicked']").should_not be_nil
    end

    it "should dispatch click when node is added in shadow DOM" do
      page.goto(server.empty_page)
      page.evaluate(%(() => {
        const div = document.createElement('div');
        div.attachShadow({mode: 'open'});
        document.body.appendChild(div);
      }))
      page.evaluate("() => new Promise(f => setTimeout(f, 100))")
      page.evaluate(%(() => {
        const span = document.createElement('span');
        span.textContent = 'Hello from shadow';
        span.addEventListener('click', () => window['clicked'] = true);
        document.querySelector('div').shadowRoot.appendChild(span);
      }))

      page.dispatch_event("span", "click")
      page.evaluate("() => window['clicked']").should be_true
    end

    it "should dispatch drag drop events" do
      page.goto(server.prefix + "/drag-n-drop.html")
      data_transfer = page.evaluate_handle("() => new DataTransfer()")
      source = page.query_selector("#source")
      source.not_nil!.dispatch_event("dragstart", {"dataTransfer" => data_transfer})
      target = page.query_selector("#target")
      target.not_nil!.dispatch_event("drop", {"dataTransfer" => data_transfer})

      page.evaluate(%(
        ({source, target}) => {
          return source.parentElement === target;
        }
      ), {"source" => source, "target" => target}).should be_true
    end

    it "should dispatch click event on handle" do
      page.goto(server.prefix + "/input/button.html")
      button = page.query_selector("button")
      button.not_nil!.dispatch_event("click")
      page.evaluate("() => window['result']").should eq("Clicked")
    end
  end
end
