require "./channel_owner"

module Playwright
  private class PlaywrightImpl < ChannelOwner
    include IPlaywright
    @process : Process?
    getter chromium : BrowserTypeImpl
    getter firefox : BrowserTypeImpl
    getter webkit : BrowserTypeImpl
    getter selectors : Selectors
    getter devices : Hash(String, DeviceDescriptor)

    def self.create
      process = Process.new(Playwright.driver_path, ["run-driver"], input: Process::Redirect::Pipe,
        output: Process::Redirect::Pipe, error: Process::Redirect::Pipe)

      connection = Connection.new(process.output, process.input)
      connection.start
      result = connection.wait_for_object_with_known_name("Playwright").as(PlaywrightImpl)
      result.process = process
      result
    end

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
      @devices = Hash(String, DeviceDescriptor).new

      @chromium = parent.connection.get_existing_object(jsinitializer["chromium"]["guid"].as_s).as(BrowserTypeImpl)
      @firefox = parent.connection.get_existing_object(jsinitializer["firefox"]["guid"].as_s).as(BrowserTypeImpl)
      @webkit = parent.connection.get_existing_object(jsinitializer["webkit"]["guid"].as_s).as(BrowserTypeImpl)
      @selectors = parent.connection.get_existing_object(jsinitializer["selectors"]["guid"].as_s).as(Selectors)

      jsinitializer["deviceDescriptors"].as_a.each do |item|
        name = item["name"].as_s
        descriptor = DeviceDescriptor.from_json(item["descriptor"].to_json)
        descriptor.playwright = self
        @devices[name] = descriptor
      end
    end

    def process=(process : Process)
      @process = process
    end

    def close
      connection.close
      @process.try &.terminate
    end
  end
end
