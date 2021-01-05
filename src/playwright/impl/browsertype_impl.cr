require "./channel_owner"
require "../browsertype"

module Playwright
  private class BrowserTypeImpl < ChannelOwner
    include BrowserType

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
    end

    def launch(options : LaunchOptions?) : Browser
      options ||= LaunchOptions.new
      params = JSON.parse(options.to_json)
      result = send_message("launch", params)
      connection.get_existing_object(result["browser"]["guid"].as_s).as(BrowserImpl)
    end

    def executable_path : String
      jsinitializer["executablePath"].as_s
    end

    def launch_persistent_context(user_data_dir : Path, options : LaunchPersistentContextOptions?) : BrowserContext
      options ||= LaunchPersistentContextOptions.new
      params = JSON.parse(options.to_json)
      if hdrs = options.extra_http_headers
        params.as_h.delete("extraHTTPHeaders")
        params.as_h["extraHTTPHeaders"] = Serialization.to_protocol(hdrs)
      end
      params.as_h["userDataDir"] = JSON::Any.new(user_data_dir.to_s)
      result = send_message("launchPersistentContext", params)
      connection.get_existing_object(result["context"]["guid"].as_s).as(BrowserContextImpl)
    end

    def name : String
      jsinitializer["name"].as_s
    end
  end
end
