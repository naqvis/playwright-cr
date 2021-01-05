require "./spec_helper"

module Playwright
  it "should navigate subframes" do
    page.goto(server.prefix + "/frames/one-frame.html")
    page.frames[0].url.includes?("/frames/one-frame.html").should be_true
    page.frames[1].url.includes?("/frames/frame.html").should be_true

    resp = page.frames[1].goto(server.empty_page) || fail "unable to get frame navigation response"
    resp.ok.should be_true
    page.frames[1].should eq(resp.frame)
  end

  it "should continue after client redirect" do
    server.add_handler("/frames/script.js") { |_|
      sleep 5
    }
    url = server.prefix + "/frames/child-redirect.html"
    begin
      page.goto(url, Page::NavigateOptions.new(timeout: 5000, wait_until: Frame::LoadState::NETWORKIDLE))
      fail "expected to raise timeout exception"
    rescue ex
      ex.message.try &.includes?("Timeout 5000ms exceeded.").should be_true
      ex.message.try &.includes?("navigating to \"#{url}\", waiting until \"networkidle\"").should be_true
    end
  end
end
