require "./spec_helper"

module Playwright
  describe Dialog do
    it "should fire dialog listener" do
      page.add_listener(Page::EventType::DIALOG, ListenerImpl(Page::EventType).new { |event|
        dialog = event.data.as(Dialog)
        dialog.type.should eq(Dialog::Type::ALERT)
        dialog.default_value.should eq("")
        dialog.message.should eq("yo")
        dialog.accept
      })
      page.evaluate("() => alert('yo')")
    end

    it "should allow accepting prompts" do
      page.add_listener(Page::EventType::DIALOG, ListenerImpl(Page::EventType).new { |event|
        dialog = event.data.as(Dialog)
        dialog.type.should eq(Dialog::Type::PROMPT)
        dialog.default_value.should eq("yes.")
        dialog.message.should eq("question?")
        dialog.accept("answer!")
      })
      page.evaluate("() => prompt('question?', 'yes.')").should eq("answer!")
    end

    it "should dismiss the prompt" do
      page.add_listener(Page::EventType::DIALOG, ListenerImpl(Page::EventType).new { |event|
        dialog = event.data.as(Dialog)
        dialog.dismiss
      })
      page.evaluate("() => prompt('question?')").should eq(nil)
    end

    it "should accept the confirm prompt" do
      page.add_listener(Page::EventType::DIALOG, ListenerImpl(Page::EventType).new { |event|
        dialog = event.data.as(Dialog)
        dialog.accept
      })
      page.evaluate("() => confirm('boolean?')").should be_true
    end

    it "should dismiss the confirm prompt" do
      page.add_listener(Page::EventType::DIALOG, ListenerImpl(Page::EventType).new { |event|
        dialog = event.data.as(Dialog)
        dialog.dismiss
      })
      page.evaluate("() => confirm('boolean?')").should be_false
    end

    it "should be able to close context with open alert" do
      {% if flag?(:darwin) %}
        next if webkit?
      {% end %}
      context = browser.new_context
      page = context.new_page
      page.evaluate("() => { setTimeout(() => alert('hello'),0);}")
      context.close
    end
  end
end
