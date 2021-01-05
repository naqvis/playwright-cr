require "./spec_helper"

module Playwright
  describe "EvalOnSelector" do
    it "should work with css selector" do
      page.set_content("<section id='testAttribute'>43543</section>")
      id = page.eval_on_selector("css=section", "e => e.id")
      id.should eq("testAttribute")
    end

    it "should work with id selector" do
      page.set_content("<section id='testAttribute'>43543</section>")
      id = page.eval_on_selector("id=testAttribute", "e => e.id")
      id.should eq("testAttribute")
    end

    it "should work with data test selector" do
      page.set_content("<section data-test=foo id='testAttribute'>43543</section>")
      id = page.eval_on_selector("data-test=foo", "e => e.id")
      id.should eq("testAttribute")
    end

    it "should work with data testid selector" do
      page.set_content("<section data-testid=foo id='testAttribute'>43543</section>")
      id = page.eval_on_selector("data-testid=foo", "e => e.id")
      id.should eq("testAttribute")
    end

    it "should work with text selector" do
      page.set_content("<section id='testAttribute'>43543</section>")
      id = page.eval_on_selector("text=43543", "e => e.id")
      id.should eq("testAttribute")
    end

    it "should work with xpath selector" do
      page.set_content("<section id='testAttribute'>43543</section>")
      id = page.eval_on_selector("xpath=/html/body/section", "e => e.id")
      id.should eq("testAttribute")
    end

    it "should auto detect css selector" do
      page.set_content("<section id='testAttribute'>43543</section>")
      id = page.eval_on_selector("section", "e => e.id")
      id.should eq("testAttribute")
    end

    it "should auto detect css selector with attributes" do
      page.set_content("<section id='testAttribute'>43543</section>")
      id = page.eval_on_selector("section[id='testAttribute']", "e => e.id")
      id.should eq("testAttribute")
    end

    it "shoudl auto detect nested selectors" do
      page.set_content("<div foo=bar><section>43543<span>Hello<div id=target></div></span></section></div>")
      id = page.eval_on_selector("div[foo=bar] > section >> 'Hello' >> div", "e => e.id")
      id.should eq("target")
    end

    it "should accept arguments" do
      page.set_content("<section>hello</section>")
      text = page.eval_on_selector("section", "(e, suffix) => e.textContent + suffix", " world!")
      text.should eq("hello world!")
    end

    it "should accept element handle as arguments" do
      page.set_content("<section>hello</section><div> world</div>")
      div = page.query_selector("div") || fail "unable to get div handle"
      text = page.eval_on_selector("section", "(e, div) => e.textContent + div.textContent", div)
      text.should eq("hello world")
    end

    it "should raise if no element is found" do
      expect_raises(PlaywrightException, "failed to find element matching selector \"section\"") do
        page.eval_on_selector("section", "e => e.id")
      end
    end

    it "should support syntax" do
      page.set_content("<section><div>hello</div></section>")
      text = page.eval_on_selector("css=section >> css=div", "(e, suffix) => e.textContent + suffix", " world!")
      text.should eq("hello world!")
    end

    it "should support syntax with different engines" do
      page.set_content("<section><div><span>hello</span></div></section>")
      text = page.eval_on_selector("xpath=/html/body/section >> css=div >> text='hello'", "(e, suffix) => e.textContent + suffix", " world!")
      text.should eq("hello world!")
    end

    it "should work with spaces in css attributes when missing" do
      promise = page.wait_for_selector("[placeholder='Select date']")
      page.query_selector("[placeholder='Select date']").should be_nil
      page.set_content("<div><input placeholder='Select date'></div>")
      promise.get
    end

    it "should return complex values" do
      page.set_content("<section id='testAttribute'>43543</section>")
      id = page.eval_on_selector("css=section", "e => [{ id: e.id }]")
      id.should eq([{"id" => "testAttribute"}])
    end
  end

  describe "EvalOnSelectorAll" do
    it "should work with css selector" do
      page.set_content("<div>hello</div><div>beautiful</div><div>world!</div>")
      divs = page.eval_on_selector_all("css=div", "divs => divs.length")
      divs.should eq(3)
    end

    it "should work with text selector" do
      page.set_content("<div>hello</div><div>beautiful</div><div>beautiful</div><div>world!</div>")
      divs = page.eval_on_selector_all("text='beautiful'", "divs => divs.length")
      divs.should eq(2)
    end

    it "should work with xpath selector" do
      page.set_content("<div>hello</div><div>beautiful</div><div>world!</div>")
      divs = page.eval_on_selector_all("xpath=/html/body/div", "divs => divs.length")
      divs.should eq(3)
    end

    it "should support capture when multiple paths match" do
      page.set_content("<div><div><span></span></div></div><div></div>")
      page.eval_on_selector_all("*css=div >> span", "els => els.length").should eq(2)
      page.set_content("<div><div><span></span></div><span></span><span></span></div><div></div>")
      page.eval_on_selector_all("*css=div >> span", "els => els.length").should eq(2)
    end

    it "should return complex values" do
      page.set_content("<div>hello</div><div>beautiful</div><div>world!</div>")
      texts = page.eval_on_selector_all("css=div", "divs => divs.map(div => div.textContent)")
      texts.should eq(["hello", "beautiful", "world!"])
    end
  end

  describe "Selector Register" do
    it "should work" do
      selector_script = %({
        create(root, target) {
          return target.nodeName;
        },
        query(root, selector) {
          return root.querySelector(selector);
        },
        queryAll(root, selector) {
          return Array.from(root.querySelectorAll(selector));
        }
      })

      # Register one engine before creating context
      playwright.selectors.register("tag", selector_script)

      context = browser.new_context
      # Register another engine after creating context
      playwright.selectors.register("tag2", selector_script)

      page = context.new_page
      page.set_content("<div><span></span></div><div></div>")

      page.eval_on_selector("tag=DIV", "e => e.nodeName").should eq("DIV")
      page.eval_on_selector("tag=SPAN", "e => e.nodeName").should eq("SPAN")
      page.eval_on_selector_all("tag=DIV", "es => es.length").should eq(2)

      page.eval_on_selector("tag2=DIV", "e => e.nodeName").should eq("DIV")
      page.eval_on_selector("tag2=SPAN", "e => e.nodeName").should eq("SPAN")
      page.eval_on_selector_all("tag2=DIV", "es => es.length").should eq(2)

      expect_raises(PlaywrightException, %(Unknown engine "tAG" while parsing selector tAG=DIV)) do
        # selector names are case-sensitive
        page.query_selector("tAG=DIV")
      end

      context.close
    end

    it "should work with path selector" do
      playwright.selectors.register("foo", Path["#{RESOURCE_DIR}/sectionselectorengine.js"])
      page.set_content("<section></section>")
      page.eval_on_selector("foo=whatever", "e => e.nodeName").should eq("SECTION")
    end

    it "should work in main and isolated world" do
      dummy_selector = %({
        create(root, target) { },
        query(root, selector) {
          return window['__answer'];
        },
        queryAll(root, selector) {
          return window['__answer'] ? [window['__answer'], document.body, document.documentElement] : [];
        }
      })

      playwright.selectors.register("main", dummy_selector)
      playwright.selectors.register("isolated", dummy_selector, Selectors::RegisterOptions.new(content_script: true))

      page.set_content("<div><span><section></section></span></div>")
      page.evaluate("() => window['__answer'] = document.querySelector('span')")
      # Works in main if asked
      page.eval_on_selector("main=ignored", "e => e.nodeName").should eq("SPAN")
      page.eval_on_selector("css=div >> main=ignored", "e => e.nodeName").should eq("SPAN")
      page.eval_on_selector_all("main=ignored", "es => window['__answer'] !== undefined").should be_true
      page.eval_on_selector_all("main=ignored", "es => es.filter(e => e).length").should eq(3)

      # Works in isolated by default
      page.query_selector("isolated=ignored").should be_nil
      page.query_selector("css=div >> isolated=ignored").should be_nil
      page.eval_on_selector_all("isolated=ignored", "es => window['__answer'] !== undefined").should be_true
      page.eval_on_selector_all("isolated=ignored", "es => es.filter(e => e).length").should eq(3)

      # At least one engine in main forces all to be in main
      page.eval_on_selector("main=ignored >> isolated=ignored", "e => e.nodeName").should eq("SPAN")
      page.eval_on_selector("isolated=ignored >> main=ignored", "e => e.nodeName").should eq("SPAN")

      # Can be chained to css
      page.eval_on_selector("main=ignored >> css=section", "e => e.nodeName").should eq("SECTION")
    end
  end
end
