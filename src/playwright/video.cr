require "json"

module Playwright
  # When browser context is created with the `videosPath` option, each page has a video object associated with it.
  #
  module Video
    # Returns the file system path this video will be recorded to. The video is guaranteed to be written to the filesystem upon closing the browser context.
    abstract def path : String
  end
end
