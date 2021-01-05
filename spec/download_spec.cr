require "./spec_helper"

module Playwright
  Spec.before_each {
    server.add_handler("/download") { |context|
      context.response.content_type = "application/octet-stream"
      context.response.headers["Content-Disposition"] = "attachment"
      context.response.status = :ok
      content = "Hello world"
      context.response.content_length = content.bytesize
      context.response.write(content.to_slice)
    }

    server.add_handler("/downloadWithFilename") { |context|
      context.response.content_type = "application/octet-stream"
      context.response.headers["Content-Disposition"] = "attachment; filename=file.txt"
      context.response.status = :ok
      content = "Hello world"
      context.response.content_length = content.bytesize
      context.response.write content.to_slice
    }
  }

  describe "Download" do
    it "should report downloads with accept downloads false" do
      page.set_content("<a href='#{server.prefix}/downloadWithFilename'>download</a>")
      download_event = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download = download_event.get.try &.data.as(Download) || fail "no download object found"
      download.url.should eq("#{server.prefix}/downloadWithFilename")
      download.suggested_filename.should eq("file.txt")
      begin
        download.path
        fail "did not raise exception"
      rescue ex
        download.failure.try &.includes?("acceptDownloads").should be_true
        ex.message.not_nil!.includes?("acceptDownloads: true").should be_true
      end
    end

    it "should report downloads with accept downloads true" do
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: true))
      page.set_content("<a href='#{server.prefix}/download'>download</a>")
      download_event = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download = download_event.get.try &.data.as(Download) || fail "no download object found"
      path = download.path
      File.exists?(path.not_nil!).should be_true
      contents = File.read(path.not_nil!)
      contents.should eq("Hello world")
      page.close
    end

    it "should save to user specified path" do
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: true))
      page.set_content("<a href='#{server.prefix}/download'>download</a>")
      download_event = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download = download_event.get.try &.data.as(Download) || fail "no download object found"

      tempfile = File.tempname("download", ".txt")
      download.save_as(tempfile)
      File.exists?(tempfile).should be_true

      contents = File.read(tempfile)
      contents.should eq("Hello world")
      File.delete(tempfile)
      page.close
    end

    it "should save to two different paths with multiple save_as calls" do
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: true))
      page.set_content("<a href='#{server.prefix}/download'>download</a>")
      download_event = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download = download_event.get.try &.data.as(Download) || fail "no download object found"

      tempfile = File.tempname("download1", ".txt")
      download.save_as(tempfile)
      File.exists?(tempfile).should be_true
      contents = File.read(tempfile)
      contents.should eq("Hello world")
      File.delete(tempfile)

      tempfile = File.tempname("download2", ".txt")
      download.save_as(tempfile)
      File.exists?(tempfile).should be_true
      contents = File.read(tempfile)
      contents.should eq("Hello world")
      File.delete(tempfile)

      page.close
    end

    it "should save to overwritten file path" do
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: true))
      page.set_content("<a href='#{server.prefix}/download'>download</a>")
      download_event = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download = download_event.get.try &.data.as(Download) || fail "no download object found"

      tempfile = File.tempname("download", ".txt")
      download.save_as(tempfile)
      File.exists?(tempfile).should be_true
      contents = File.read(tempfile)
      contents.should eq("Hello world")

      download.save_as(tempfile)
      File.exists?(tempfile).should be_true
      contents = File.read(tempfile)
      contents.should eq("Hello world")
      File.delete(tempfile)
      page.close
    end

    it "should report error with accept downloads disabled" do
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: false))
      page.set_content("<a href='#{server.prefix}/download'>download</a>")
      download_event = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download = download_event.get.try &.data.as(Download) || fail "no download object found"
      tempfile = File.tempname("download", ".txt")
      expect_raises(PlaywrightException, "Pass { acceptDownloads: true } when you are creating your browser context") do
        download.save_as(tempfile)
      end
      page.close
    end

    it "should error when saving after deletion" do
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: true))
      page.set_content("<a href='#{server.prefix}/download'>download</a>")
      download_event = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download = download_event.get.try &.data.as(Download) || fail "no download object found"

      tempfile = File.tempname("download", ".txt")
      download.delete

      expect_raises(PlaywrightException, "Download already deleted. Save before deleting.") do
        download.save_as(tempfile)
      end
      page.close
    end

    it "should report non navigation downloads" do
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: true))
      page.goto(server.empty_page)
      page.set_content("<a download='file.txt' href='#{server.prefix}/download'>download</a>")
      download_event = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download = download_event.get.try &.data.as(Download) || fail "no download object found"
      download.suggested_filename.should eq("file.txt")
      path = download.path
      File.exists?(path.not_nil!).should be_true
      contents = File.read(path.not_nil!)
      contents.should eq("Hello world")
      page.close
    end

    it "should expose stream" do
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: true))
      page.set_content("<a href='#{server.prefix}/download'>download</a>")
      download_event = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download = download_event.get.try &.data.as(Download) || fail "no download object found"

      stream = download.create_read_stream
      output = IO::Memory.new
      IO.copy(stream.not_nil!, output)
      output.to_s.should eq("Hello world")
      page.close
    end

    it "should delete downloads on context destruction" do
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: true))
      page.set_content("<a href='#{server.prefix}/download'>download</a>")
      download_event1 = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download1 = download_event1.get.try &.data.as(Download) || fail "no download object found"

      download_event2 = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download2 = download_event2.get.try &.data.as(Download) || fail "no download object found"

      path1 = download1.path || raise "Path is nil"
      path2 = download2.path || raise "Path is nil"

      File.exists?(path1).should be_true
      File.exists?(path2).should be_true
      page.context.close
      File.exists?(path1).should be_false
      File.exists?(path2).should be_false
    end

    it "should delete downloads on browser gone" do
      browser = browser_type.launch
      page = browser.new_page(Browser::NewPageOptions.new(accept_downloads: true))
      page.set_content("<a href='#{server.prefix}/download'>download</a>")
      download_event1 = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download1 = download_event1.get.try &.data.as(Download) || fail "no download object found"

      download_event2 = page.wait_for_event(Page::EventType::DOWNLOAD)
      page.click("a")
      download2 = download_event2.get.try &.data.as(Download) || fail "no download object found"

      path1 = download1.path || raise "Path is nil"
      path2 = download2.path || raise "Path is nil"

      File.exists?(path1).should be_true
      File.exists?(path2).should be_true
      browser.close
      File.exists?(path1).should be_false
      File.exists?(path2).should be_false
    end
  end
end
