require "./channel_owner"
require "../selectors"

module Playwright
  private class SelectorsImpl < ChannelOwner
    include Selectors

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
    end

    def register(name : String, script : String, options : RegisterOptions?)
      options ||= RegisterOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["name"] = JSON::Any.new(name)
      params.as_h["source"] = JSON::Any.new(script)
      send_message("register", params)
    end

    def register(name : String, path : Path, options : RegisterOptions?)
      buffer = File.read(path) || raise PlaywrightException.new("Failed to read selector from file: #{path}.")
      register(name, buffer, options)
    end
  end
end
