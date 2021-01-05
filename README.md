# 🎭 [Playwright](https://playwright.dev) for Crystal ![CI](https://github.com/naqvis/playwright-cr/workflows/CI/badge.svg) [![GitHub release](https://img.shields.io/github/release/naqvis/playwright-cr.svg)](https://github.com/naqvis/playwright-cr/releases)


#### [Website](https://playwright.dev/) |  [API Reference](https://naqvis.github.io/playwright-cr/)

**Playwright-cr** is a Crystal library to automate [Chromium](https://www.chromium.org/Home), [Firefox](https://www.mozilla.org/en-US/firefox/new/) and [WebKit](https://webkit.org/) with a single API. Playwright is built to enable cross-browser web automation that is **ever-green**, **capable**, **reliable** and **fast**. [See how Playwright is better](https://playwright.dev/#path=docs%2Fwhy-playwright.md&q=).


|          | Linux | macOS | Windows |
|   :---   | :---: | :---: | :---:   |
| Chromium <!-- GEN:chromium-version -->89.0.4344.0<!-- GEN:stop --> | ✅ | ✅ | ✅ |
| WebKit 14.1 | ✅ | ✅ | ✅ |
| Firefox <!-- GEN:firefox-version -->85.0b1<!-- GEN:stop --> | ✅ | ✅ | ✅ |

Headless execution is supported for all the browsers on all platforms. Check out [system requirements](https://playwright.dev/#?path=docs/intro.md&q=system-requirements) for details.

# Playwright Dependencies
Playwright Crystal relies on two external components: The Playwright driver and the browsers.

## Playwright Driver

Playwright drivers will be downloaded to the `bin/driver` folder, and browsers will be installed at shard installation time.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     playwright:
       github: naqvis/playwright-cr
   ```

2. Run `shards install`

## Usage

### Page Screenshot

This code snippet navigates to whatsmyuseragent.org in Chromium, Firefox and WebKit, and saves 3 screenshots.
```crystal
require "playwright"

playwright = Playwright.create
browser_types = [playwright.chromium,
                 playwright.webkit,
                 playwright.firefox]

browser_types.each do |browser_type|
  browser = browser_type.launch
  context = browser.new_context(Playwright::Browser::NewContextOptions.new(
    viewport: Playwright::Page::ViewPort.new(800, 600)))
  page = context.new_page
  page.goto("http://whatsmyuseragent.org/")
  page.screenshot(Playwright::Page::ScreenshotOptions.new(path: Path["screenshot-#{browser_type.name}.png"]))
  browser.close
end
playwright.close
```

### Mobile and geolocation

This snippet emulates Mobile Chromium on a device at a given geolocation, navigates to openstreetmap.org, performs action and takes a screenshot.
```crystal
require "playwright"

playwright = Playwright.create
browser = playwright.chromium.launch(Playwright::BrowserType::LaunchOptions.new(headless: false))
pixel2 = playwright.devices["Pixel 2"]
context = browser.new_context(Playwright::Browser::NewContextOptions.new(
  viewport: Playwright::Page::ViewPort.new(pixel2.viewport.width, pixel2.viewport.height),
  user_agent: pixel2.user_agent,
  device_scale_factor: pixel2.device_scale_factor.to_i,
  is_mobile: pixel2.is_mobile,
  has_touch: pixel2.has_touch,
  locale: "en-US",
  geolocation: Playwright::Geolocation.new(41.889938, 12.492507),
  permissions: ["geolocation"]))
page = context.new_page
page.goto("https://www.openstreetmap.org/")
page.click("a[data-original-title=\"Show My Location\"]")
page.screenshot(Playwright::Page::ScreenshotOptions.new(path: Path["colosseum-pixel2.png"]))
browser.close
playwright.close

```

### Evaluate in browser context

This code snippet navigates to example.com in Firefox, and executes a script in the page context.
```crystal
require "playwright"

playwright = Playwright.create
browser = playwright.firefox.launch(Playwright::BrowserType::LaunchOptions.new(headless: false))
context = browser.new_context
page = context.new_page
page.goto("https://www.example.com/")
dimensions = page.evaluate(%(
  () => {
    return {
      width: document.documentElement.clientWidth,
      height: document.documentElement.clientHeight,
      deviceScaleFactor: window.devicePixelRatio
    }
  }
))
puts dimensions # => {"width" => 1280, "height" => 720, "deviceScaleFactor" => 1}
browser.close
playwright.close
```

### Intercept network requests

This code snippet sets up request routing for a WebKit page to log all network requests.
```crystal
require "playwright"

playwright = Playwright.create
browser = playwright.webkit.launch
context = browser.new_context
page = context.new_page
page.route("**", Playwright::Consumer(Playwright::Route).new { |route|
  puts route.request.url
  route.continue
})
page.goto("http://todomvc.com")
browser.close
playwright.close
```

Refer to `spec` for more samples and usages. This shard comes with **350+** test cases :)
## Development

To run all tests:

```
crystal spec
```
By Default browser is `chromium`, but you can change the browser via setting environment variable of `BROWSER=firefox` or `BROWSER=webkit` for specs to run using different browser.
By default tests are run in **headless** mode. But if you would like the tests to run in headful way, set the environment variable `HEADFUL=true`.

## Contributing

1. Fork it (<https://github.com/naqvis/playwright-cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ali Naqvi](https://github.com/naqvis) - creator and maintainer
