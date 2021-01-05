require "path"
require "json"

module Playwright
  # Download objects are dispatched by page via the page.on('download') event.
  # All the downloaded files belonging to the browser context are deleted when the browser context is closed. All downloaded files are deleted when the browser closes.
  # Download event is emitted once the download starts. Download path becomes available once download completes:
  #
  #
  # **NOTE** Browser context **must** be created with the `acceptDownloads` set to `true` when user needs access to the downloaded content. If `acceptDownloads` is not set or set to `false`, download events are emitted, but the actual download is not performed and user has no access to the downloaded files.
  module Download
    # Returns readable stream for current download or `null` if download failed.
    abstract def create_read_stream : IO?
    # Deletes the downloaded file.
    abstract def delete : Nil
    # Returns download error if any.
    abstract def failure : String?
    # Returns path to the downloaded file in case of successful download.
    abstract def path : Path?
    # Saves the download to a user-specified path.
    abstract def save_as(path : Path) : Nil
    # Returns suggested filename for this download. It is typically computed by the browser from the `Content-Disposition` response header or the `download` attribute. See the spec on whatwg. Different browsers can use different logic for computing it.
    abstract def suggested_filename : String
    # Returns downloaded url.
    abstract def url : String
  end
end
