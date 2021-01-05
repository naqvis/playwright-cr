require "./spec_helper"

module Playwright
  it "should be able to save pdf to file" do
    next unless chromium?
    next if headful?

    path = Path[File.tempname("output", ".pdf")]
    page.pdf(Page::PdfOptions.new(path: path))
    File.info(path).size.should be > 0
  end

  it "Should only have PDF in chromium" do
    next if chromium?
    expect_raises(PlaywrightException, "Page.pdf only supported in headless Chromium") do
      page.pdf
    end
  end
end
