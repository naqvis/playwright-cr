require "spec"
require "path"
require "http/server"
require "../src/playwright"

Spec.before_suite {
  Playwright.launch_browser
  Playwright.start_server
}

Spec.after_suite {
  Playwright.close_browser
  Playwright.stop_server
  Playwright.close_playwright
}

Spec.before_each {
  Playwright.create_context_and_page
}

Spec.after_each {
  Playwright.close_context rescue nil
}

module Playwright
  RESOURCE_DIR   = "spec/resources"
  FILE_TO_UPLOAD = Path[RESOURCE_DIR, "file-to-upload.txt"]

  @@head_ful : Bool = false
  @@playwright : PlaywrightImpl?
  @@browser_type : BrowserType?
  @@browser : Browser?
  @@server : Server?

  @@context : BrowserContext?
  @@page : Page?

  def self.context
    @@context.not_nil!
  end

  def self.page
    @@page.not_nil!
  end

  def self.playwright
    @@playwright.not_nil!
  end

  def self.browser_type
    @@browser_type.not_nil!
  end

  def self.browser
    @@browser.not_nil!
  end

  def self.headful?
    @@head_ful
  end

  def self.firefox?
    browser_type.name == "firefox"
  end

  def self.chromium?
    browser_type.name == "chromium"
  end

  def self.webkit?
    browser_type.name == "webkit"
  end

  def self.create_launch_options
    env = ENV["HEADFUL"]?
    @@head_ful = !env.nil? && env != "0" && env != "false"
    options = BrowserType::LaunchOptions.new
    options.headless = !@@head_ful
    options
  end

  def self.launch_browser(options)
    @@playwright = create
    browser_name = ENV["BROWSER"]? || "chromium"
    case browser_name
    when "webkit"   then @@browser_type = playwright.webkit
    when "firefox"  then @@browser_type = playwright.firefox
    when "chromium" then @@browser_type = playwright.chromium
    else                 raise ArgumentError.new("Uknown browser: #{browser_name}")
    end

    @@browser = browser_type.launch(options)
  end

  def self.launch_browser
    launch_browser(create_launch_options)
  end

  def self.close_browser
    browser.try &.close
  end

  def self.server
    @@server.not_nil!
  end

  def self.start_server
    server = Server.new(8082)
    @@server = server
    server.start
  end

  def self.stop_server
    @@server.try &.stop
  end

  def self.close_playwright
    playwright.try &.close
  end

  def self.create_context
    browser.not_nil!.new_context
  end

  def self.create_context_and_page
    @@context = create_context
    @@page = context.new_page
  end

  def self.close_context
    server.reset
    context.close
    @@context = nil
    @@page = nil
  end

  def self.attach_frame(page : Page, name : String, url : String) : Frame?
    handle = page.evaluate_handle(%(async ({ frameId, url }) => {
        const frame = document.createElement('iframe');
        frame.src = url;
        frame.id = frameId;
        document.body.appendChild(frame);
        await new Promise(x => frame.onload = x);
        return frame;
  }
    ), {"frameId" => JSON::Any.new(name), "url" => JSON::Any.new(url)})
    handle.as_element.try &.content_frame
  end

  class Server
    getter port : Int32
    getter prefix : String
    getter cross_process_prefix : String
    getter empty_page : String

    def initialize(@port)
      @prefix = "http://localhost:#{@port}"
      @cross_process_prefix = "http://127.0.0.1:#{@port}"
      @empty_page = @prefix + "/empty.html"
      @custom = CustomHandler.new
      ws_handler = HTTP::WebSocketHandler.new do |ws, _|
        ws.send("incoming")
      end
      @server = HTTP::Server.new([
        @custom,
        ws_handler,
        HTTP::ErrorHandler.new,
        HTTP::LogHandler.new,
        HTTP::CompressHandler.new,
        HTTP::StaticFileHandler.new(RESOURCE_DIR),
      ])
    end

    def start
      @server.bind_tcp "127.0.0.1", port
      spawn { @server.listen }
    end

    def stop
      @server.close
    end

    def add_handler(path : String, &handler : HTTP::Server::Context -> Nil)
      @custom.add_handler(path, handler)
    end

    def reset
      @custom.reset
    end

    private class CustomHandler
      include HTTP::Handler

      @chandlers : Hash(String, Proc(HTTP::Server::Context, Nil))

      def initialize
        @chandlers = Hash(String, Proc(HTTP::Server::Context, Nil)).new
      end

      def add_handler(path : String, handler : HTTP::Server::Context -> Nil)
        @chandlers[path] = handler
      end

      def reset
        @chandlers.clear
      end

      def call(context : HTTP::Server::Context)
        if h = @chandlers[context.request.path.not_nil!]?
          h.call(context)
          return
        end
        call_next(context)
      end
    end
  end
end
