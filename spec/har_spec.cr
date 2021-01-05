require "./spec_helper"

module Playwright
  describe "Har" do
    it "should have version and creator" do
      page_with_har.page.goto(server.empty_page)
      log = page_with_har.log
      log["version"].as_s.should eq("1.2")
      log["creator"]["name"].as_s.should eq("Playwright")
    end

    it "should have browser" do
      page_with_har.page.goto(server.empty_page)
      log = page_with_har.log
      log["browser"]["name"].as_s.downcase.should eq(browser_type.name)
      log["browser"]["version"].as_s.should eq(browser.version)
    end

    it "should have pages" do
      page_with_har.page.goto("data:text/html,<title>Hello</title>")
      # For data: load comes before domcontentloaded...
      event = page_with_har.page.wait_for_load_state(Page::LoadState::DOMCONTENTLOADED)
      event.get
      log = page_with_har.log
      log["pages"].as_a.size.should eq(1)
      page_entry = log["pages"].as_a[0]
      page_entry["id"].as_s.should eq("page_0")
      page_entry["title"].as_s.should eq("Hello")

      page_entry["pageTimings"]["onContentLoad"].as_i.should be > 0
      page_entry["pageTimings"]["onLoad"].as_i.should be > 0
    end

    it "should have pages in persistent context" do
      harpath = page_with_har.har_file
      user_data_dir = Path[File.tempname("user-data-dir")]
      Dir.mkdir_p(user_data_dir)
      context = browser_type.launch_persistent_context(user_data_dir,
        BrowserType::LaunchPersistentContextOptions.new(
          record_har: BrowserType::LaunchPersistentContextOptions::RecordHar.new(harpath),
          ignore_https_errors: true))
      page = context.pages[0]

      page.goto("data:text/html,<title>Hello</title>")
      # For data: load comes before domcontentloaded...
      event = page.wait_for_load_state(Page::LoadState::DOMCONTENTLOADED)
      event.get
      context.close
      log = JSON.parse(File.read(harpath))["log"]
      log["pages"].as_a.size.should eq(1)
      page_entry = log["pages"].as_a[0]
      page_entry["id"].as_s.should eq("page_0")
      page_entry["title"].as_s.should eq("Hello")
    end

    it "should include request" do
      page_with_har.page.goto(server.empty_page)
      log = page_with_har.log
      log["entries"].as_a.size.should eq(1)
      entry = log["entries"].as_a[0]
      entry["pageref"].as_s.should eq("page_0")
      entry["request"]["url"].as_s.should eq(server.empty_page)
      entry["request"]["method"].as_s.should eq("GET")
      entry["request"]["httpVersion"].as_s.should eq("HTTP/1.1")
      entry["request"]["headers"].as_a.size.should be > 1

      found_agent = false
      entry["request"]["headers"].as_a.each do |item|
        if item["name"].as_s.downcase == "user-agent"
          found_agent = true
          break
        end
      end
      found_agent.should be_true
    end

    it "should include response" do
      page_with_har.page.goto(server.empty_page)
      log = page_with_har.log
      entry = log["entries"].as_a[0]
      entry["response"]["status"].as_i.should eq(200)
      entry["response"]["statusText"].as_s.should eq("OK")
      entry["response"]["httpVersion"].as_s.should eq("HTTP/1.1")
      entry["response"]["headers"].as_a.size.should be > 1

      found_content_type = false
      entry["response"]["headers"].as_a.each do |item|
        if item["name"].as_s.downcase == "content-type"
          found_content_type = true
          item["value"].as_s.downcase.should eq("text/html")
          break
        end
      end
      # found_content_type.should be_true
    end
  end

  private class PageWithHar
    getter har_file : Path
    getter context : BrowserContext
    getter page : Page

    def initialize(browser : Browser)
      @har_file = Path[File.tempname("test", ".har")]
      @context = browser.new_context(Browser::NewContextOptions.new(
        record_har: Browser::NewContextOptions::RecordHar.new(path: @har_file),
        ignore_https_errors: true))
      @page = @context.new_page
    end

    def log
      context.close
      JSON.parse(File.read(@har_file))["log"]
    end

    def dispose
      context.close
      File.delete(har_file) rescue nil
    end
  end

  @@page_with_har : PageWithHar?

  def self.page_with_har
    @@page_with_har.not_nil!
  end

  Spec.before_each {
    @@page_with_har = PageWithHar.new(browser)
  }

  Spec.after_each {
    page_with_har.dispose
  }
end
