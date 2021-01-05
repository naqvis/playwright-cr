require "./channel_owner"
require "../browser"

module Playwright
  private class BrowserImpl < ChannelOwner
    include Browser
    @contexts : Set(BrowserContext)
    getter listeners : ListenerCollection(EventType)

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
      @contexts = Set(BrowserContext).new
      @listeners = ListenerCollection(EventType).new
      @is_connected = true
    end

    def add_listener(type : EventType, listener : Listener(EventType))
      listeners.add(type, listener)
    end

    def remove_listener(type : EventType, listener : Listener(EventType))
      listeners.remove(type, listener)
    end

    def close : Nil
      send_message("close")
    rescue ex : PlaywrightException
      raise ex unless Utils.safe_close_error?(ex)
    end

    def contexts : Array(BrowserContext)
      @contexts.to_a
    end

    # :nodoc:
    def delete_context(context)
      @contexts.delete(context)
    end

    def is_connected : Bool
      @is_connected
    end

    def context_options
      NewContextOptions.from_json(%({}))
    end

    def new_context(options : NewContextOptions?) : BrowserContext
      options ||= NewContextOptions.new
      if path = options.storage_state_path
        begin
          options.storage_state = BrowserContext::StorageState.from_json(File.read(path))
          options.storage_state_path = nil
        rescue ex
          raise PlaywrightException.new("Failed to read storage state from file: #{ex.message}")
        end
      end
      params = JSON.parse(options.to_json)
      if hdrs = options.extra_http_headers
        params.as_h.delete("extraHTTPHeaders")
        params.as_h["extraHTTPHeaders"] = Serialization.to_protocol(hdrs)
      end

      result = send_message("newContext", params)
      context = connection.get_existing_object(result["context"]["guid"].as_s).as(BrowserContextImpl)
      @contexts.add(context)
      context
    end

    def new_page(options : NewPageOptions?) : Page
      options ||= NewPageOptions.new
      context = new_context(NewContextOptions.from_json(options.to_json))
      page = context.new_page
      context.owner_page = page
      page.owned_context = context
      page
    end

    def name : String
      jsinitializer["name"].as_s
    end

    def version : String
      jsinitializer["version"].as_s
    end

    def chromium?
      name == "chromium"
    end

    def handle_event(event : String, _param : JSON::Any)
      if event == "close"
        @is_connected = false
        listeners.notify(EventType::DISCONNECTED, nil)
      end
    end
  end
end
