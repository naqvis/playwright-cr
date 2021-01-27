module Playwright
  VERSION = "0.1.1"
  # :nodoc:
  alias Number = Int64 | Float64
  # :nodoc:
  alias DataTypes = JSHandle | JSHandleImpl | Frame | Frame::LoadState | Page | WebSocket |
                    WebSocket::FrameData | Worker | Dialog | ConsoleMessage | Download |
                    FileChooser | Request | Response | Page::Error | Nil
  alias Any = JSON::Any::Type | JSON::Any | DataTypes | Hash(String, DataTypes) | Hash(String, JSON::Any::Type) |
              Hash(String, Int32)

  class PlaywrightException < Exception
  end

  class ServerException < PlaywrightException
    def initialize(error : SerializedError::Error)
      super(error.name + ": " + error.message)
    end
  end

  module IPlaywright
    abstract def chromium : BrowserType
    abstract def firefox : BrowserType
    abstract def webkit : BrowserType
    abstract def devices : Hash(String, DeviceDescriptor)
    abstract def selectors : Selectors
    abstract def close
  end

  def self.create : IPlaywright
    PlaywrightImpl.create
  end

  # :nodoc:
  def self.driver_path
    cli = "playwright-cli"
    {% if flag?(:windows) %}
      cli = "playwright-cli.exe"
    {% end %}
    path = ENV["driver_cli"]? || Path[Path[{{__DIR__}}].parent, "bin", "driver", cli].to_s
    raise PlaywrightException.new("Playwright CLI not found. [#{path}]") unless File.exists?(path)
    path
  end
end

require "./playwright/**"
