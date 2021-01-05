require "json"

module Playwright
  # TimeoutError is emitted whenever certain operations are terminated due to timeout, e.g. `page.waitForSelector(selector[, options])` or `browserType.launch([options])`.
  module TimeoutError
  end
end
