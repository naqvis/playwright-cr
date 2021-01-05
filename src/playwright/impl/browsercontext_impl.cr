require "./channel_owner"
require "../browsercontext"

module Playwright
  private class BrowserContextImpl < ChannelOwner
    include BrowserContext

    getter! browser : BrowserImpl
    getter pages : Array(PageImpl)
    getter routes : Router
    getter bindings : Hash(String, Page::Binding)
    getter timeout_settings : TimeoutSettings
    property owner_page : PageImpl?
    getter listeners : ListenerCollection(EventType)

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
      @pages = Array(PageImpl).new
      @routes = Router.new
      @is_closed_or_closing = false
      @bindings = Hash(String, Page::Binding).new
      @listeners = ListenerCollection(EventType).new
      @timeout_settings = TimeoutSettings.new

      @browser = parent.as?(BrowserImpl)
    end

    def add_listener(type : EventType, listener : Listener(EventType))
      listeners.add(type, listener)
    end

    def remove_listener(type : EventType, listener : Listener(EventType))
      listeners.remove(type, listener)
    end

    # :nodoc:
    def delete_page(page)
      @pages.delete(page)
    end

    def close : Nil
      return if @is_closed_or_closing
      @is_closed_or_closing = true
      begin
        send_message("close")
      rescue ex : PlaywrightException
        raise ex unless Utils.safe_close_error?(ex)
      end
    end

    def add_cookies(cookies : Array(AddCookie))
      params = Hash(String, JSON::Any).new
      params["cookies"] = JSON.parse(cookies.to_json)
      send_message("addCookies", JSON::Any.new(params))
    end

    def add_init_script(script : String, _arg : Any?) : Nil
      script = "(#{script})" if function_body?(script)
      json = JSON.build do |js|
        js.object do
          js.field "source", script
        end
      end
      send_message("addInitScript", JSON.parse(json))
    end

    def clear_cookies : Nil
      send_message("clearCookies")
    end

    def clear_permissions : Nil
      send_message("clearPermissions")
    end

    def cookies(url : Array(String)) : Array(Cookie)
      parms = JSON.build do |json|
        json.object do
          json.field "urls", url
        end
      end
      ret = send_message("cookies", JSON.parse(parms))
      Array(Cookie).from_json(ret["cookies"].to_json)
    end

    def expose_binding(name : String, playwright_binding : Page::Binding, options : ExposeBindingOptions?) : Nil
      raise PlaywrightException.new("Function \"#{name}\" has been already registered") if bindings.has_key?(name)
      pages.each do |page|
        raise PlaywrightException.new("Function \"#{name}\" has been already registered in one of the pages") if page.bindings.has_key?(name)
      end
      bindings[name] = playwright_binding
      params = JSON.build do |json|
        json.object do
          json.field "name", name
          json.field("needsHandle", true) if options.try &.handle
        end
      end
      send_message("exposeBinding", JSON.parse(params))
    end

    def expose_function(name : String, playwright_function : Page::Function) : Nil
      expose_binding(name, BindingHelper.new(playwright_function))
    end

    def grant_permissions(permissions : Array(String), options : GrantPermissionsOptions?) : Nil
      options ||= GrantPermissionsOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["permissions"] = JSON.parse(permissions.to_json)
      send_message("grantPermissions", params)
    end

    def new_page : Page
      raise PlaywrightException.new("Please use browser.new_context") unless owner_page.nil?
      ret = send_message("newPage")
      connection.get_existing_object(ret["page"]["guid"].as_s).as(PageImpl)
    end

    def pages : Array(Page)
      @pages.map { |p| p.as(Page) }
    end

    def route(url : String, handler : Consumer(Route))
      route(UrlMatcher.new(url), handler)
    end

    def route(url : Regex, handler : Consumer(Route))
      route(UrlMatcher.new(url), handler)
    end

    def route(url : (String) -> Bool, handler : Consumer(Route))
      route(UrlMatcher.new(url), handler)
    end

    def set_default_navigation_timeout(timeout : Int32) : Nil
      timeout_settings.set_default_navigation_timeout(timeout)
      params = {"timeout" => timeout}
      send_message("setDefaultNavigationTimeoutNoReply", JSON.parse(params.to_json))
    end

    def set_default_timeout(timeout : Int32) : Nil
      timeout_settings.set_default_timeout(timeout)
      params = {"timeout" => timeout}
      send_message("setDefaultTimeoutNoReply", JSON.parse(params.to_json))
    end

    def set_extra_http_headers(headers : Hash(String, String)) : Nil
      params = JSON.build do |json|
        json.object do
          json.field "headers" do
            json.array do
              headers.each do |k, v|
                json.object do
                  json.field "name", k
                  json.field "value", v
                end
              end
            end
          end
        end
      end
      send_message("setExtraHTTPHeaders", JSON.parse(params))
    end

    def set_geolocation(geolocation : Geolocation?) : Nil
      params = JSON::Any.new(Hash(String, JSON::Any).new)
      params.as_h["geolocation"] = JSON.parse(geolocation.to_json) if geolocation
      send_message("setGeolocation", params)
    end

    def set_offline(offline : Bool) : Nil
      params = JSON.build do |json|
        json.object do
          json.field "offline", offline
        end
      end
      send_message("setOffline", JSON.parse(params))
    end

    def storage_state(options : StorageStateOptions?) : StorageState
      json = send_message("storageState")
      storage_state = StorageState.from_json(json.to_json)
      if (opt = options) && (opt.path)
        Dir.mkdir_p(opt.path.parent)
        File.write(opt.path, json.to_json)
      end
      storage_state
    end

    def unroute(url : String, handler : Consumer(Route)?)
      unroute(UrlMatcher.new(url), handler)
    end

    def unroute(url : Regex, handler : Consumer(Route)?)
      unroute(UrlMatcher.new(url), handler)
    end

    def unroute(url : (String) -> Bool, handler : Consumer(Route)?)
      unroute(UrlMatcher.new(url), handler)
    end

    def wait_for_event(event : EventType, options : WaitForEventOptions?) : Deferred(Event(EventType))
      options ||= WaitForEventOptions.new

      waitables = Array(Waitable(Event(EventType))).new
      waitables << WaitableEvent(Event(EventType)).new(listeners, event, options.predicate)
      waitables << WaitableTimeout(Event(EventType)).new(timeout_settings.create_waitable(options.timeout))
      to_deferred(WaitableRace(Event(EventType)).new(waitables))
    end

    def handle_event(event : String, params : JSON::Any)
      case event
      when "route"
        route = connection.get_existing_object(params["route"]["guid"].as_s).as(RouteImpl)
        route.continue unless routes.handle(route)
      when "page"
        page = connection.get_existing_object(params["page"]["guid"].as_s).as(PageImpl)
        listeners.notify(EventType::PAGE, page)
        @pages << page
      when "bindingCall"
        bindcall = connection.get_existing_object(params["binding"]["guid"].as_s).as(BindingCall)
        binding = bindings[bindcall.name]?
        bindcall.call(binding) if binding
      when "close"
        @is_closed_or_closing = true
        if (b = browser?)
          b.delete_context(self)
        end
        listeners.notify(EventType::CLOSE, nil)
      end
    end

    private def route(matcher, handler)
      routes.add(matcher, handler)
      if routes.size == 1
        params = {"enabled" => true}
        send_message("setNetworkInterceptionEnabled", JSON.parse(params.to_json))
      end
    end

    private def unroute(matcher, handler)
      routes.remove(matcher, handler)
      if routes.size == 0
        params = {"enabled" => false}
        send_message("setNetworkInterceptionEnabled", JSON.parse(params.to_json))
      end
    end

    private class BindingHelper
      include Page::Binding

      def initialize(@func : Page::Function)
      end

      def call(_source : Source, args : Array(Any)) : Any
        @func.call(args)
      end
    end
  end
end
