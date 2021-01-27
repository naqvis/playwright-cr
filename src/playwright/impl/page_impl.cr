require "./channel_owner"
require "../page"

module Playwright
  private class PageImpl < ChannelOwner
    include Page

    private getter browser_context : BrowserContextImpl
    @frame : FrameImpl?
    @keyboard : KeyboardImpl?
    @mouse : MouseImpl?
    @accessibility : AccessibilityImpl?
    @touchscreen : TouchscreenImpl?
    getter viewport : ViewPort?
    private getter routes : Router
    @frames : Set(Frame)
    getter(listeners : ListenerCollection(EventType)) { ListenerCollection(EventType).new }
    getter bindings : Hash(String, Binding)
    property owned_context : BrowserContextImpl?
    @workers : Set(Worker)
    getter timeout_settings : TimeoutSettings

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
      @routes = Router.new
      @frames = Set(Frame).new
      @bindings = Hash(String, Binding).new
      @workers = Set(Worker).new

      @browser_context = parent.as(BrowserContextImpl)
      @timeout_settings = TimeoutSettings.new(@browser_context.timeout_settings)
    end

    def handle_event(event : String, params : JSON::Any)
      case event
      when "dialog"
        dialog = connection.get_existing_object(params["dialog"]["guid"].as_s).as(DialogImpl)
        listeners.notify(EventType::DIALOG, dialog)
        # If no action taken dismiss dialog to not hang
        dialog.dismiss unless dialog.handled?
      when "popup"
        popup = connection.get_existing_object(params["page"]["guid"].as_s).as(PageImpl)
        listeners.notify(EventType::POPUP, popup)
      when "worker"
        worker = connection.get_existing_object(params["worker"]["guid"].as_s).as(WorkerImpl)
        worker.page = self
        @workers.add(worker)
        listeners.notify(EventType::WORKER, worker)
      when "webSocket"
        ws = connection.get_existing_object(params["webSocket"]["guid"].as_s).as(WebSocketImpl)
        listeners.notify(EventType::WEBSOCKET, ws)
      when "console"
        console = connection.get_existing_object(params["message"]["guid"].as_s).as(ConsoleMessageImpl)
        listeners.notify(EventType::CONSOLE, console)
      when "download"
        download = connection.get_existing_object(params["download"]["guid"].as_s).as(DownloadImpl)
        listeners.notify(EventType::DOWNLOAD, download)
      when "fileChooser"
        elem = connection.get_existing_object(params["element"]["guid"].as_s).as(ElementHandleImpl)
        chooser = FileChooserImpl.new(self, elem, params["isMultiple"].as_bool)
        listeners.notify(EventType::FILECHOOSER, chooser)
      when "bindingCall"
        binding_call = connection.get_existing_object(params["binding"]["guid"].as_s).as(BindingCall)
        binding = bindings[binding_call.name]?
        binding = browser_context.bindings[binding_call.name] if binding.nil?
        if (bind = binding)
          binding_call.call(bind)
        end
      when "load"
        listeners.notify(EventType::LOAD, nil)
      when "domcontentloaded"
        listeners.notify(EventType::DOMCONTENTLOADED, nil)
      when "request"
        request = connection.get_existing_object(params["request"]["guid"].as_s).as(RequestImpl)
        listeners.notify(EventType::REQUEST, request)
      when "requestFailed"
        request = connection.get_existing_object(params["request"]["guid"].as_s).as(RequestImpl)
        if params["failureText"]?
          request.failure = Request::RequestFailure.new(params["failureText"].as_s)
        end
        listeners.notify(EventType::REQUESTFAILED, request)
      when "requestFinished"
        request = connection.get_existing_object(params["request"]["guid"].as_s).as(RequestImpl)
        listeners.notify(EventType::REQUESTFINISHED, request)
      when "response"
        response = connection.get_existing_object(params["response"]["guid"].as_s).as(ResponseImpl)
        listeners.notify(EventType::RESPONSE, response)
      when "frameAttached"
        frame = connection.get_existing_object(params["frame"]["guid"].as_s).as(FrameImpl)
        @frames.add(frame)
        frame.page = self
        if parent = frame.parent_frame
          parent.add_child_frame(frame)
        end
        listeners.notify(EventType::FRAMEATTACHED, frame)
      when "frameDetached"
        frame = connection.get_existing_object(params["frame"]["guid"].as_s).as(FrameImpl)
        @frames.delete(frame)
        frame.is_detached = true
        if parent = frame.parent_frame
          parent.remove_child_frame(frame)
        end
        listeners.notify(EventType::FRAMEDETACHED, frame)
      when "route"
        route = connection.get_existing_object(params["route"]["guid"].as_s).as(RouteImpl)
        handled = routes.handle(route)
        handled = browser_context.routes.handle(route) unless handled
        route.continue unless handled
      when "pageError"
        error = SerializedError.from_json(params["error"].to_json)
        listeners.notify(EventType::PAGEERROR, ErrorImpl.new(error))
      when "crash"
        listeners.notify(EventType::CRASH, nil)
      when "close"
        @is_closed = true
        browser_context.delete_page(self)
        listeners.notify(EventType::CLOSE, nil)
      end
    end

    def main_frame : FrameImpl
      if (mf = @frame)
        mf
      else
        frame = connection.get_existing_object(jsinitializer["mainFrame"]["guid"].as_s).as(FrameImpl)
        frame.page = self
        @frames.add(frame)
        @frame = frame
        frame
      end
    end

    def add_listener(type : EventType, listener : Listener(EventType))
      will_add_file_chooser_listener if type == EventType::FILECHOOSER
      listeners.add(type, listener)
    end

    def remove_listener(type : EventType, listener : Listener(EventType))
      listeners.remove(type, listener)
      did_remove_file_chooser_listener if type == EventType::FILECHOOSER
    end

    def close(options : CloseOptions?) : Nil
      options ||= CloseOptions.new
      params = JSON.parse(options.to_json)
      begin
        send_message("close", params)
      rescue ex : PlaywrightException
        raise ex unless Utils.safe_close_error?(ex)
      end
      @owned_context.try &.close
    end

    def query_selector(selector : String) : ElementHandle?
      main_frame.query_selector(selector)
    end

    def query_selector_all(selector : String) : Array(ElementHandle)
      main_frame.query_selector_all(selector)
    end

    def eval_on_selector(selector : String, page_function : String, arg : Array(Any)?) : Any
      main_frame.eval_on_selector(selector, page_function, arg)
    end

    def eval_on_selector_all(selector : String, page_function : String, arg : Array(Any)?) : Any
      main_frame.eval_on_selector_all(selector, page_function, arg)
    end

    def add_init_script(script : String, _arg : Any) : Nil
      params = {"source" => script}
      # TODO: support or drop arg
      send_message("addInitScript", JSON.parse(params.to_json))
    end

    def add_script_tag(script : AddScriptTagScript) : ElementHandle
      main_frame.add_script_tag(Frame::AddScriptTagScript.from_json(script.to_json))
    end

    def add_style_tag(style : AddStyleTagStyle) : ElementHandle
      main_frame.add_style_tag(Frame::AddStyleTagStyle.from_json(style.to_json))
    end

    def bring_to_front : Nil
      send_message("bringToFront")
    end

    def check(selector : String, options : CheckOptions?) : Nil
      if o = options
        main_frame.check(selector, Frame::CheckOptions.from_json(o.to_json))
      else
        main_frame.check(selector, nil)
      end
    end

    def click(selector : String, options : ClickOptions?) : Nil
      if o = options
        main_frame.click(selector, Frame::ClickOptions.from_json(o.to_json))
      else
        main_frame.click(selector, nil)
      end
    end

    def content : String
      main_frame.content
    end

    def context : BrowserContext
      @browser_context
    end

    def dblclick(selector : String, options : DblclickOptions?) : Nil
      if o = options
        main_frame.dblclick(selector, Frame::DblclickOptions.from_json(o.to_json))
      else
        main_frame.dblclick(selector, nil)
      end
    end

    def dispatch_event(selector : String, type : String, event_init : Array(Any)?, options : DispatchEventOptions?) : Nil
      if o = options
        main_frame.dispatch_event(selector, type, event_init, Frame::DispatchEventOptions.from_json(o.to_json))
      else
        main_frame.dispatch_event(selector, type, event_init, nil)
      end
    end

    def emulate_media(params : EmulateMediaParams) : Nil
      send_message("emulateMedia", JSON.parse(params.to_json))
    end

    def evaluate(page_function : String, arg : Array(Any)?) : Any
      main_frame.evaluate(page_function, arg)
    end

    def evaluate_handle(page_function : String, arg : Array(Any)?) : JSHandle
      main_frame.evaluate_handle(page_function, arg)
    end

    def expose_binding(name : String, playwright_binding : Binding, options : ExposeBindingOptions?) : Nil
      raise PlaywrightException.new("Function \"#{name}\" has been already registered") if bindings.has_key?(name)
      raise PlaywrightException.new("Function \"#{name}\" has been already registered in browser context") if @browser_context.bindings.has_key?(name)
      bindings[name] = playwright_binding
      params = JSON.build do |json|
        json.object do
          json.field "name", name
          json.field "needsHandle", true if options.try &.handle
        end
      end
      send_message("exposeBinding", JSON.parse(params))
    end

    def expose_function(name : String, playwright_function : Function) : Nil
      expose_binding(name, PageBindingHelper.new(playwright_function), nil)
    end

    def fill(selector : String, value : String, options : FillOptions?) : Nil
      if o = options
        main_frame.fill(selector, value, Frame::FillOptions.from_json(o.to_json))
      else
        main_frame.fill(selector, value, nil)
      end
    end

    def focus(selector : String, options : FocusOptions?) : Nil
      if o = options
        main_frame.focus(selector, Frame::FocusOptions.from_json(o.to_json))
      else
        main_frame.focus(selector, nil)
      end
    end

    def frame_by_name(name : String) : Frame?
      @frames.find { |f| f.name == name }
    end

    def frame_by_url(glob : String) : Frame?
      frame_for(UrlMatcher.new(glob))
    end

    def frame_by_url(pattern : Regex) : Frame?
      frame_for(UrlMatcher.new(pattern))
    end

    def frame_by_url(predicate : (String) -> Bool) : Frame?
      frame_for(UrlMatcher.new(predicate))
    end

    def frames : Array(Frame)
      @frames.to_a.as(Array(Frame))
    end

    def get_attribute(selector : String, name : String, options : GetAttributeOptions?) : String?
      if o = options
        main_frame.get_attribute(selector, name, Frame::GetAttributeOptions.from_json(o.to_json))
      else
        main_frame.get_attribute(selector, name, nil)
      end
    end

    def go_back(options : GoBackOptions?) : Response?
      options ||= GoBackOptions.new
      options.wait_until = Frame::LoadState::LOAD if options.wait_until.nil?
      json = send_message("goBack", JSON.parse(options.to_json))
      if resp = json["response"]?
        return connection.get_existing_object(resp["guid"].as_s).as(ResponseImpl)
      end
      nil
    end

    def go_forward(options : GoForwardOptions?) : Response?
      options ||= GoForwardOptions.new
      options.wait_until = Frame::LoadState::LOAD if options.wait_until.nil?
      json = send_message("goForward", JSON.parse(options.to_json))
      if resp = json["response"]?
        return connection.get_existing_object(resp["guid"].as_s).as(ResponseImpl)
      end
      nil
    end

    def goto(url : String, options : NavigateOptions? = nil) : Response?
      if o = options
        main_frame.goto(url, Frame::NavigateOptions.from_json(o.to_json))
      else
        main_frame.goto(url, nil)
      end
    end

    def hover(selector : String, options : HoverOptions?) : Nil
      if o = options
        main_frame.hover(selector, Frame::HoverOptions.from_json(o.to_json))
      else
        main_frame.hover(selector, nil)
      end
    end

    def inner_html(selector : String, options : InnerHTMLOptions?) : String
      if o = options
        main_frame.inner_html(selector, Frame::InnerHTMLOptions.from_json(o.to_json))
      else
        main_frame.inner_html(selector, nil)
      end
    end

    def inner_text(selector : String, options : InnerTextOptions?) : String
      if o = options
        main_frame.inner_text(selector, Frame::InnerTextOptions.from_json(o.to_json))
      else
        main_frame.inner_text(selector, nil)
      end
    end

    def is_closed : Bool
      @is_closed || false
    end

    def opener : Page?
      json = send_message("opener")
      return nil unless json["page"]?
      connection.get_existing_object(json["page"]["guid"].as_s).as(PageImpl)
    end

    def pdf(options : PdfOptions?) : Bytes
      raise PlaywrightException.new("Page.pdf only supported in headless Chromium") unless browser_context.browser.chromium?
      options ||= PdfOptions.new
      params = JSON.parse(options.to_json).as_h
      params.delete("path")
      json = send_message("pdf", JSON.parse(params.to_json))
      buffer = Base64.decode(json["pdf"].as_s)
      File.write(options.path.not_nil!, buffer) if options.path
      buffer
    end

    def press(selector : String, key : String, options : PressOptions?) : Nil
      if o = options
        main_frame.press(selector, key, Frame::PressOptions.from_json(o.to_json))
      else
        main_frame.press(selector, key, nil)
      end
    end

    def reload(options : ReloadOptions?) : Response?
      options ||= ReloadOptions.new
      options.wait_until = Frame::LoadState::LOAD if options.wait_until.nil?
      json = send_message("reload", JSON.parse(options.to_json))
      if resp = json["response"]?
        return connection.get_existing_object(resp["guid"].as_s).as(ResponseImpl)
      end
      nil
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

    def screenshot(options : ScreenshotOptions?) : Bytes
      options ||= ScreenshotOptions.new
      if options.type.nil?
        options.type = ScreenshotOptions::Type::PNG
        if !options.path.nil?
          ext = options.path.not_nil!.extension.downcase
          options.type = ScreenshotOptions::Type::JPEG if [".jpeg", ".jpg"].includes?(ext)
        end
      end

      params = JSON.parse(options.to_json).as_h
      params.delete("path")
      json = send_message("screenshot", JSON.parse(params.to_json))

      buffer = Base64.decode(json["binary"].as_s)
      File.write(options.path.not_nil!, buffer) if options.path
      buffer
    end

    def select_option(selector : String, values : Array(ElementHandle::SelectOption)?, options : SelectOptionOptions?)
      if o = options
        main_frame.select_option(selector, values, Frame::SelectOptionOptions.from_json(o.to_json))
      else
        main_frame.select_option(selector, values, nil)
      end
    end

    def select_option(selector : String, values : Array(ElementHandle)?, options : SelectOptionOptions?)
      if o = options
        main_frame.select_option(selector, values, Frame::SelectOptionOptions.from_json(o.to_json))
      else
        main_frame.select_option(selector, values, nil)
      end
    end

    def set_content(html : String, options : SetContentOptions?) : Nil
      if o = options
        main_frame.set_content(html, Frame::SetContentOptions.from_json(o.to_json))
      else
        main_frame.set_content(html, nil)
      end
    end

    def set_default_navigation_timeout(timeout : Int32) : Nil
      timeout_settings.default_navigation_timeout = timeout
      params = {"timeout" => JSON::Any.new(timeout.to_i64)}
      send_message("setDefaultNavigationTimeoutNoReply", JSON::Any.new(params))
    end

    def set_default_timeout(timeout : Int32) : Nil
      timeout_settings.default_timeout = timeout
      params = {"timeout" => JSON::Any.new(timeout.to_i64)}
      send_message("setDefaultTimeoutNoReply", JSON::Any.new(params))
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

    def set_input_files(selector : String, file : Array(FileChooser::FilePayload), options : SetInputFilesOptions?)
      if o = options
        main_frame.set_input_files(selector, file, Frame::SetInputFilesOptions.from_json(o.to_json))
      else
        main_frame.set_input_files(selector, file, nil)
      end
    end

    def set_input_files(selector : String, file : Array(Path), options : SetInputFilesOptions?)
      if o = options
        main_frame.set_input_files(selector, file, Frame::SetInputFilesOptions.from_json(o.to_json))
      else
        main_frame.set_input_files(selector, file, nil)
      end
    end

    def set_viewport_size(width : Int32, height : Int32)
      viewport = ViewPort.new(width, height)
      params = {"viewportSize" => JSON.parse(viewport.to_json)}
      send_message("setViewportSize", JSON.parse(params.to_json))
    end

    def tap(selector : String, options : TapOptions?) : Nil
      if o = options
        main_frame.tap(selector, Frame::TapOptions.from_json(o.to_json))
      else
        main_frame.tap(selector, nil)
      end
    end

    def text_content(selector : String, options : TextContentOptions?) : String?
      if o = options
        main_frame.text_content(selector, Frame::TextContentOptions.from_json(o.to_json))
      else
        main_frame.text_content(selector, nil)
      end
    end

    def title : String
      main_frame.title
    end

    def type(selector : String, text : String, options : TypeOptions?) : Nil
      if o = options
        main_frame.type(selector, text, Frame::TypeOptions.from_json(o.to_json))
      else
        main_frame.type(selector, text, nil)
      end
    end

    def uncheck(selector : String, options : UncheckOptions?) : Nil
      if o = options
        main_frame.uncheck(selector, Frame::UncheckOptions.from_json(o.to_json))
      else
        main_frame.uncheck(selector, nil)
      end
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

    def url : String
      main_frame.url
    end

    def video : Video?
      nil
    end

    def viewport_size : ViewPort?
      viewport
    end

    def wait_for_event(event : EventType, options : WaitForEventOptions?) : Deferred(Event(EventType))
      options ||= WaitForEventOptions.new

      waitables = Array(Waitable(Event(EventType))).new
      if event == EventType::FILECHOOSER
        will_add_file_chooser_listener
        waitables << WaitableEventHelper.new(listeners, event, options.predicate, self)
      else
        waitables << WaitableEvent(EventType).new(listeners, event, options.predicate)
      end
      waitables << CreateWaitable(Event(EventType)).new(timeout_settings, options.timeout).get
      to_deferred(WaitableRace(Event(EventType)).new(waitables))
    end

    def wait_for_function(page_function : String, arg : Array(Any)?, options : WaitForFunctionOptions?) : Deferred(JSHandle)
      if o = options
        main_frame.wait_for_function(page_function, arg, Frame::WaitForFunctionOptions.from_json(o.to_json))
      else
        main_frame.wait_for_function(page_function, arg, nil)
      end
    end

    def wait_for_load_state(state : LoadState?, options : WaitForLoadStateOptions?) : Deferred(Nil)
      state = state ? Frame::LoadState.from_json(state.to_json) : nil
      if o = options
        main_frame.wait_for_load_state(state, Frame::WaitForLoadStateOptions.from_json(o.to_json))
      else
        main_frame.wait_for_load_state(state, nil)
      end
    end

    def frame_navigated(frame : FrameImpl)
      listeners.notify(EventType::FRAMENAVIGATED, frame)
    end

    def wait_for_navigation(options : WaitForNavigationOptions?) : Deferred(Response?)
      options ||= WaitForNavigationOptions.new
      fopts = Frame::WaitForNavigationOptions.new
      if opt = options
        fopts.timeout = opt.timeout
        fopts.wait_until = opt.wait_until
        fopts.url = opt.url
      end

      main_frame.wait_for_navigation(fopts)
    end

    def wait_for_request(url_glob : String, options : WaitForRequestOptions?) : Deferred(Request?)
      wait_for_request(UrlMatcher.new(url_glob), options)
    end

    def wait_for_request(url_pattern : Regex, options : WaitForRequestOptions?) : Deferred(Request?)
      wait_for_request(UrlMatcher.new(url_pattern), options)
    end

    def wait_for_request(predicate : (String -> Bool)?, options : WaitForRequestOptions?) : Deferred(Request?)
      wait_for_request(UrlMatcher.new(predicate), options)
    end

    def wait_for_response(url_glob : String, options : WaitForResponseOptions?) : Deferred(Response?)
      wait_for_response(UrlMatcher.new(url_glob), options)
    end

    def wait_for_response(url_pattern : Regex, options : WaitForResponseOptions?) : Deferred(Response?)
      wait_for_response(UrlMatcher.new(url_pattern), options)
    end

    def wait_for_response(predicate : (String -> Bool)?, options : WaitForResponseOptions?) : Deferred(Response?)
      wait_for_response(UrlMatcher.new(predicate), options)
    end

    def wait_for_selector(selector : String, options : WaitForSelectorOptions?) : Deferred(ElementHandle?)
      if o = options
        main_frame.wait_for_selector(selector, Frame::WaitForSelectorOptions.from_json(o.to_json))
      else
        main_frame.wait_for_selector(selector, nil)
      end
    end

    def wait_for_timeout(timeout : Int32) : Deferred(Nil)
      main_frame.wait_for_timeout(timeout)
    end

    def workers : Array(Worker)
      @workers.to_a
    end

    def delete_worker(worker : Worker)
      @workers.delete(worker)
    end

    def accessibility : Accessibility
      @accessibility ||= AccessibilityImpl.new(self)
    end

    def keyboard : Keyboard
      @keyboard ||= KeyboardImpl.new(self)
    end

    def mouse : Mouse
      @mouse ||= MouseImpl.new(self)
    end

    def touchscreen : Touchscreen
      @touchscreen ||= TouchscreenImpl.new(self)
    end

    def create_waitable_frame_detach(frame : Frame)
      WaitableFrameDetach.new(listeners, frame)
    end

    private def wait_for_request(matcher : UrlMatcher, options : WaitForRequestOptions?)
      options ||= WaitForRequestOptions.new
      waitables = Array(Waitable(Request?)).new
      waitables << WaitableEvent(EventType).new(listeners, EventType::REQUEST,
        ->(e : Event(EventType)) { matcher.test(e.data.as(Request).url) }).apply ->(evt : Event(EventType)) { evt.data.as?(Request) }
      waitables << WaitablePageClose(Request?).new(self)
      waitables << CreateWaitable(Request?).new(timeout_settings, options.timeout).get

      to_deferred(WaitableRace(Request?).new(waitables))
    end

    private def wait_for_response(matcher : UrlMatcher, options : WaitForResponseOptions?)
      options ||= WaitForResponseOptions.new
      waitables = Array(Waitable(Response?)).new
      waitables << WaitableEvent(EventType).new(listeners, EventType::RESPONSE,
        ->(e : Event(EventType)) { matcher.test(e.data.as(Response).url) }).apply ->(evt : Event(EventType)) { evt.data.as?(Response) }
      waitables << WaitablePageClose(Response?).new(self)
      waitables << CreateWaitable(Response?).new(timeout_settings, options.timeout).get

      to_deferred(WaitableRace(Response?).new(waitables))
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

    private def frame_for(matcher)
      @frames.find { |f| matcher.test(f.url) }
    end

    private def will_add_file_chooser_listener
      unless listeners.has_listeners(EventType::FILECHOOSER)
        update_file_chooser_interception(true)
      end
    end

    def did_remove_file_chooser_listener
      unless listeners.has_listeners(EventType::FILECHOOSER)
        update_file_chooser_interception(false)
      end
    end

    private def update_file_chooser_interception(enabled : Bool)
      params = {"intercepted" => enabled}
      send_message("setFileChooserInterceptedNoReply", JSON.parse(params.to_json))
    end

    private class WaitableEventHelper < WaitableEvent(EventType)
      def initialize(listeners, type, predicate = nil, @page : PageImpl? = nil)
        super(listeners, type, predicate)
      end

      def dispose
        super
        @page.try &.did_remove_file_chooser_listener
      end
    end

    private class ErrorImpl
      include Error

      def initialize(@error : SerializedError)
      end

      def message : String
        @error.error.try &.message || ""
      end

      def name : String
        @error.error.try &.name || ""
      end

      def stack : String
        @error.error.try &.stack || ""
      end
    end

    private class WaitableFrameDetach < WaitableEvent(EventType)
      def initialize(listeners, frame : Frame)
        super(listeners, EventType::FRAMEDETACHED, ->(evt : Event(EventType)) { frame == evt.data })
      end

      def get : Event(EventType)
        raise PlaywrightException.new("Navigating frame was detached")
      end
    end

    class WaitablePageClose(R) < Waitable(R)
      getter subscribed_events : Array(EventType)

      @event_handler : ListenerImpl(EventType)

      def initialize(@page : PageImpl)
        @error_message = ""
        @subscribed_events = [EventType::CLOSE, EventType::CRASH]
        @event_handler = ListenerImpl(EventType).new { |event|
          case event.type
          when .close? then @error_message = "Page closed"
          when .crash? then @error_message = "Page crashed"
          else
            next
          end
        }
        subscribed_events.each { |e| @page.add_listener(e, @event_handler) }
      end

      def done? : Bool
        !@error_message.blank?
      end

      def get : R
        raise PlaywrightException.new(@error_message)
      end

      def dispose
        subscribed_events.each { |e| @page.remove_listener(e, @event_handler) }
      end
    end

    private class PageBindingHelper
      include Binding

      def initialize(@func : Function)
      end

      def call(_source : Source, args : Array(Any)) : Any
        @func.call(args)
      end
    end
  end
end
