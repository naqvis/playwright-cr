require "./spec_helper"

module Playwright
  describe Accessibility do
    it "test set_content and snapshot" do
      page.set_content(%q(
      <head>
        <title>Accessibility Test</title>
      </head>
      <body>
        <h1>Inputs</h1>
        <input placeholder='Empty input' autofocus />
        <input placeholder='readonly input' readonly />
        <input placeholder='disabled input' disabled />
        <input aria-label='Input with whitespace' value='  ' />
        <input value='value only' />
        <input aria-placeholder='placeholder' value='and a value' />
        <div aria-hidden='true' id='desc'>This is a description!</div>
        <input aria-placeholder='placeholder' value='and a value' aria-describedby='desc' />
      </body>
    ))

      # autofocus happens after a delay in chrome these days
      page.wait_for_function(%(() => document.activeElement.hasAttribute('autofocus')))

      firefox = <<-FF
      {
        "role": "document",
        "name": "Accessibility Test",
        "children": [
          {"role": "heading", "name": "Inputs", "level": 1},
          {"role": "textbox", "name": "Empty input", "focused": true},
          {"role": "textbox", "name": "readonly input", "readonly": true},
          {"role": "textbox", "name": "disabled input", "disabled": true},
          {"role": "textbox", "name": "Input with whitespace", "valueString": "  "},
          {"role": "textbox", "name": "", "valueString": "value only"},
          {"role": "textbox", "name": "", "valueString": "and a value"},
          {"role": "textbox", "name": "", "valueString": "and a value", "description": "This is a description!"}
        ]
      }
FF
      chromium = <<-CH
{
  "role": "WebArea",
  "name": "Accessibility Test",
  "children": [
    {"role": "heading", "name": "Inputs", "level": 1},
    {"role": "textbox", "name": "Empty input", "focused": true},
    {"role": "textbox", "name": "readonly input", "readonly": true},
    {"role": "textbox", "name": "disabled input", "disabled": true},
    {"role": "textbox", "name": "Input with whitespace", "valueString": "  "},
    {"role": "textbox", "name": "", "valueString": "value only"},
    {"role": "textbox", "name": "placeholder", "valueString": "and a value"},
    {"role": "textbox", "name": "placeholder", "valueString": "and a value", "description": "This is a description!"}
  ]
}
CH
      webkit = <<-WK
{
  "role": "WebArea",
  "name": "Accessibility Test",
  "children": [
    {"role": "heading", "name": "Inputs", "level": 1},
    {"role": "textbox", "name": "Empty input", "focused": true},
    {"role": "textbox", "name": "readonly input", "readonly": true},
    {"role": "textbox", "name": "disabled input", "disabled": true},
    {"role": "textbox", "name": "Input with whitespace", "valueString": "  " },
    {"role": "textbox", "name": "", "valueString": "value only" },
    {"role": "textbox", "name": "placeholder", "valueString": "and a value"},
    {"role": "textbox", "name": "This is a description!","valueString": "and a value"}
  ]
  }
WK
      golden = firefox? ? firefox : chromium? ? chromium : webkit

      page.accessibility.snapshot.to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "Should work with regular text" do
      page.set_content(%(<div>Hello World</div>))
      if snapshot = page.accessibility.snapshot
        node = snapshot.children.try &.[0] || fail "Snapshot with no children"
        (firefox? ? "text leaf" : "text").should eq(node.role)
        "Hello World".should eq(node.name)
      else
        fail "Unable to get snapshot"
      end
    end

    it "Test role description" do
      page.set_content(%(<div tabIndex=-1 aria-roledescription='foo'>Hi</div>))
      page.accessibility.snapshot.try &.children.try &.[0].roledescription.should eq("foo")
    end

    it "Test role orientation" do
      page.set_content(%(<a href='' role='slider' aria-orientation='vertical'>11</a>))
      page.accessibility.snapshot.try &.children.try &.[0].orientation.should eq("vertical")
    end

    it "Test autocomplete" do
      page.set_content(%(<div role='textbox' aria-autocomplete='list'>hi</div>))
      page.accessibility.snapshot.try &.children.try &.[0].autocomplete.should eq("list")
    end

    it "Test multiselectable" do
      page.set_content(%(<div role='grid' tabIndex=-1 aria-multiselectable=true>hey</div>))
      page.accessibility.snapshot.try &.children.try &.[0].multiselectable.should eq(true)
    end

    it "Test keyshortcuts" do
      page.set_content(%(<div role='grid' tabIndex=-1 aria-keyshortcuts='foo'>hey</div>))
      page.accessibility.snapshot.try &.children.try &.[0].keyshortcuts.should eq("foo")
    end

    it "Should Not Report Text Nodes Inside Controls" do
      page.set_content(%(
        <div role='tablist'>
          <div role='tab' aria-selected='true'><b>Tab1</b></div>
          <div role='tab'>Tab2</div>
        </div>
      ))
      golden = %(
        {
          "role": "#{firefox? ? "document" : "WebArea"}",
          "name": "",
          "children": [{
            "role": "tab",
            "name": "Tab1",
            "selected": true},
            {"role": "tab", "name": "Tab2"}
          ]
        }
      )
      page.accessibility.snapshot.to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "RichText Editable Fields Should Have Children" do
      next if webkit?
      page.set_content(%(
        <div contenteditable='true'>
        Edit this image: <img src='fakeimage.png' alt='my fake image'>
        </div>
      ))
      golden = firefox? ? %(
        {
          "role": "section",
          "name": "",
          "children": [{
            "role": "text leaf",
            "name": "Edit this image: "
         },
         {
          "role": "text",
          "name": "my fake image"
       }]
      }) : %(
        {
          "role": "generic",
          "name": "",
          "valueString": "Edit this image: ",
          "children": [{
            "role": "text",
            "name": "Edit this image:"
         },
         {
            "role": "img",
            "name": "my fake image"
         }]
        })
      page.accessibility.snapshot.try &.children.try &.[0].to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "RichText Editable Fields With Role Should Have Children" do
      next if webkit?
      page.set_content(%(
        <div contenteditable='true' role="textbox">
        Edit this image: <img src='fakeimage.png' alt='my fake image'>
        </div>
      ))
      golden = firefox? ? %(
        {
          "role": "textbox",
          "name": "",
          "valueString": "Edit this image: my fake image",
          "children": [{
            "role": "text",
            "name": "my fake image"
         }]
      }) : %(
        {
          "role": "textbox",
          "name": "",
          "valueString": "Edit this image: ",
          "children": [{
            "role": "text",
            "name": "Edit this image:"
         },
         {
            "role": "img",
            "name": "my fake image"
         }]
        })
      page.accessibility.snapshot.try &.children.try &.[0].to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "PlainText Editable Fields Without Role Should Not Have Content" do
      next unless chromium?
      page.set_content(%(<div contenteditable='plaintext-only'>Edit this image:<img src='fakeimage.png' alt='my fake image'></div>))
      golden = %(
        {
          "role": "generic",
          "name": ""
        }
      )
      page.accessibility.snapshot.try &.children.try &.[0].to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "PlainText Editable Fields With Role Should Not Have Children" do
      next unless chromium?
      page.set_content(%(<div contenteditable='plaintext-only' role='textbox'>Edit this image:<img src='fakeimage.png' alt='my fake image'></div>))
      golden = %(
        {
          "role": "textbox",
          "name": "",
          "valueString": "Edit this image:"
        }
      )
      page.accessibility.snapshot.try &.children.try &.[0].to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "PlainText Editable Fields With Tabindex and Without Role Should Not Have Content" do
      next unless chromium?
      page.set_content(%(<div contenteditable='plaintext-only' tabIndex=0>Edit this image:<img src='fakeimage.png' alt='my fake image'></div>))
      golden = %(
        {
          "role": "generic",
          "name": ""
        }
      )
      page.accessibility.snapshot.try &.children.try &.[0].to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "Non Editable Textbox With Role And Tabindex And Label Should Not Have Children" do
      page.set_content(%(
        <div role='textbox' tabIndex=0 aria-checked='true' aria-label='my favorite textbox'>
        this is the inner content
        <img alt='yo' src='fakeimg.png'>
        </div>
      ))

      golden = firefox? ? %(
        {
          "role": "textbox",
          "name": "my favorite textbox",
          "valueString": "this is the inner content yo"
        }
      ) : chromium? ? %(
        {
          "role": "textbox",
          "name": "my favorite textbox",
          "valueString": "this is the inner content "
        }
      ) : %(
        {
          "role": "textbox",
          "name": "my favorite textbox",
          "valueString": "this is the inner content  "
        }
      )
      page.accessibility.snapshot.try &.children.try &.[0].to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "Checkbox With Tabindex and Label Should Not Have Children" do
      page.set_content(%(
        <div role='checkbox' tabIndex=0 aria-checked='true' aria-label='my favorite checkbox'>
        this is the inner content
        <img alt='yo' src='fakeimg.png'>
        </div>
        ))
      golden = %(
        {
          "role": "checkbox",
          "name": "my favorite checkbox",
          "checked": "checked"
        }
      )
      page.accessibility.snapshot.try &.children.try &.[0].to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "Checkbox Without Label Should Not Have Children" do
      page.set_content(%(
        <div role='checkbox' aria-checked='true'>
        this is the inner content
        <img alt='yo' src='fakeimg.png'>
        </div>
        ))
      golden = firefox? ? %(
        {
          "role": "checkbox",
          "name": "this is the inner content yo",
          "checked": "checked"
        }
      ) : %(
        {
          "role": "checkbox",
          "name": "this is the inner content yo",
          "checked": "checked"
        }
      )
      page.accessibility.snapshot.try &.children.try &.[0].to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "Test query_selector with Button" do
      page.set_content(%(<button>My Button</button>))
      button = page.query_selector("button")
      golden = %(
        {
          "role": "button",
          "name": "My Button"
        }
      )
      page.accessibility.snapshot(Accessibility::SnapshotOptions.new(root: button)).try &.to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "Test query_selector with Input" do
      page.set_content(%(<input title='My Input' value='My Value'>))
      input = page.query_selector("input")
      golden = %(
        {
          "role": "textbox",
          "name": "My Input",
          "valueString": "My Value"
        }
      )
      page.accessibility.snapshot(Accessibility::SnapshotOptions.new(root: input)).try &.to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "Test query_selector on Menu" do
      page.set_content(%(
        <div role='menu' title='My Menu'>
          <div role='menuitem'>First Item</div>
          <div role='menuitem'>Second Item</div>
          <div role='menuitem'>Third Item</div>
        </div>
        ))
      menu = page.query_selector("div[role='menu']")
      orientation = webkit? ? %(, "orientation": "vertical") : ""
      golden = %(
        {
          "role": "menu",
          "name": "My Menu",
          "children": [
            {"role": "menuitem", "name": "First Item"},
            {"role": "menuitem", "name": "Second Item"},
            {"role": "menuitem", "name": "Third Item"}
          ]
          #{orientation}
        }
      )
      page.accessibility.snapshot(Accessibility::SnapshotOptions.new(root: menu)).try &.to_json.should eq(AccessibilityNode.from_json(golden).to_json)
    end

    it "Should return nil when element is no longer in DOM" do
      page.set_content(%(<button>My Button</button>))
      button = page.query_selector("button")
      page.eval_on_selector("button", "button => button.remove()")
      page.accessibility.snapshot(Accessibility::SnapshotOptions.new(root: button)).should be nil
    end

    it "Should show Unintereting nodes" do
      page.set_content(%(
        <div id='root' role='textbox'>
          <div>
            hello
              <div>
                world
              </div>
          </div>
        </div>
      ))

      root = page.query_selector("#root")
      if (snapshot = page.accessibility.snapshot(Accessibility::SnapshotOptions.new(false, root)))
        snapshot.role.should eq("textbox")
        snapshot.value_string.not_nil!.includes?("hello").should be_true
        snapshot.value_string.not_nil!.includes?("world").should be_true
        snapshot.children.should_not be_nil
      else
        fail "Snapshot returned nil, expecting value"
      end
    end

    it "Should work when there is a title" do
      page.set_content(%(
        <title>This is the title</title>
        <div>This is the content</div>
      ))

      if snapshot = page.accessibility.snapshot
        snapshot.name.should eq("This is the title")
        snapshot.children.try &.[0].name.should eq("This is the content")
      else
        fail "Snapshot returned nil, expecting value"
      end
    end
  end
end
