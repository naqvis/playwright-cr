require "./channel_owner"
require "./waitable"
require "./utils"
require "../frame"
require "../response"

module Playwright
  private class FrameImpl < ChannelOwner
    include Frame

    private enum InternalEventType
      NAVIGATED
      LOADSTATE

      def to_s
        super.downcase
      end
    end

    @parent_frame : FrameImpl?
    private getter(internal_listeners : ListenerCollection(InternalEventType)) { ListenerCollection(InternalEventType).new }
    property page : PageImpl?
    private getter load_states : Set(LoadState)
    getter name : String
    getter url : String
    property is_detached : Bool

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
      @child_frames = Set(Frame).new
      @name = jsinitializer["name"].as_s
      @url = jsinitializer["url"].as_s
      @load_states = Set(LoadState).new
      jsinitializer["loadStates"].as_a.each do |item|
        @load_states.add(LoadState.parse(item.as_s))
      end
      @is_detached = false

      if pf = jsinitializer["parentFrame"]?
        pframe = connection.get_existing_object(pf["guid"].as_s).as(FrameImpl)
        pframe.add_child_frame(self)
      end
    end

    def add_child_frame(frame : Frame)
      @child_frames.add(frame)
    end

    def remove_child_frame(frame)
      @child_frames.delete(frame)
    end

    def query_selector(selector : String) : ElementHandle?
      params = {"selector" => selector}
      json = send_message("querySelector", JSON.parse(params.to_json))
      if elem = json["element"]?
        return connection.get_existing_object(elem["guid"].as_s).as(ElementHandleImpl)
      end
      nil
    end

    def query_selector_all(selector : String) : Array(ElementHandle)
      params = {"selector" => selector}
      json = send_message("querySelectorAll", JSON.parse(params.to_json))
      if elems = json["elements"]?
        ret = Array(ElementHandle).new
        elems.as_a.each do |elem|
          ret << connection.get_existing_object(elem["guid"].as_s).as(ElementHandleImpl)
        end
        return ret
      end
      Array(ElementHandle).new
    end

    def eval_on_selector(selector : String, page_function : String, arg : Array(Any)?) : Any
      params = {
        "selector"   => JSON::Any.new(selector),
        "expression" => JSON::Any.new(page_function),
        "isFunction" => JSON::Any.new(function_body?(page_function)),
        "arg"        => JSON.parse(Serialization.serialize_argument(arg).to_json),
      } of String => JSON::Any

      json = send_message("evalOnSelector", JSON::Any.new(params))
      Serialization.deserialize(SerializedValue.from_json(json["value"].to_json))
    end

    def eval_on_selector_all(selector : String, page_function : String, arg : Array(Any)?) : Any
      params = {
        "selector"   => JSON::Any.new(selector),
        "expression" => JSON::Any.new(page_function),
        "isFunction" => JSON::Any.new(function_body?(page_function)),
        "arg"        => JSON.parse(Serialization.serialize_argument(arg).to_json),
      } of String => JSON::Any

      json = send_message("evalOnSelectorAll", JSON::Any.new(params))
      Serialization.deserialize(SerializedValue.from_json(json["value"].to_json))
    end

    def add_script_tag(script : AddScriptTagScript) : ElementHandle
      params = JSON.parse(script.to_json).as_h
      if path = script.path
        params.delete("path")
        begin
          encoded = File.read(path)
          params["content"] = JSON::Any.new("//# sourceURL=#{encoded.gsub("\n", "")}")
        rescue ex
          raise PlaywrightException.new("Failed to read from file: #{ex.message}")
        end
      end
      json = send_message("addScriptTag", JSON::Any.new(params))
      connection.get_existing_object(json["element"]["guid"].as_s).as(ElementHandleImpl)
    end

    def add_style_tag(style : AddStyleTagStyle) : ElementHandle
      params = JSON.parse(style.to_json).as_h
      if path = style.path
        params.delete("path")
        begin
          encoded = File.read(path)
          params["content"] = JSON::Any.new("/*# sourceURL=#{encoded.gsub("\n", "")}*/")
        rescue ex
          raise PlaywrightException.new("Failed to read from file: #{ex.message}")
        end
      end
      json = send_message("addStyleTag", JSON::Any.new(params))
      connection.get_existing_object(json["element"]["guid"].as_s).as(ElementHandleImpl)
    end

    def page : Page?
      @page
    end

    def check(selector : String, options : CheckOptions?) : Nil
      options ||= CheckOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      send_message("check", JSON::Any.new(params))
    end

    def child_frames : Array(Frame)
      @child_frames.to_a
    end

    def click(selector : String, options : ClickOptions?) : Nil
      options ||= ClickOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      send_message("click", JSON::Any.new(params))
    end

    def content : String
      send_message("content")["value"].as_s
    end

    def dblclick(selector : String, options : DblclickOptions?) : Nil
      options ||= DblclickOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      send_message("dblclick", JSON::Any.new(params))
    end

    def dispatch_event(selector : String, type : String, event_init : Array(Any)?, options : DispatchEventOptions?) : Nil
      options ||= DispatchEventOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      params["type"] = JSON::Any.new(type)
      params["eventInit"] = JSON.parse(Serialization.serialize_argument(event_init).to_json)
      send_message("dispatchEvent", JSON::Any.new(params))
    end

    def evaluate(page_function : String, arg : Array(Any)?) : Any
      params = Hash(String, JSON::Any).new
      params["expression"] = JSON::Any.new(page_function)
      params["world"] = JSON::Any.new("main")
      params["isFunction"] = JSON::Any.new(function_body?(page_function))
      sa = Serialization.serialize_argument(arg)
      params["arg"] = JSON.parse(sa.to_json)
      json = send_message("evaluateExpression", JSON::Any.new(params))
      Serialization.deserialize(SerializedValue.from_json(json["value"].to_json))
    end

    def evaluate_handle(page_function : String, arg : Array(Any)?) : JSHandle
      params = Hash(String, JSON::Any).new
      params["expression"] = JSON::Any.new(page_function)
      params["world"] = JSON::Any.new("main")
      params["isFunction"] = JSON::Any.new(function_body?(page_function))
      params["arg"] = JSON.parse(Serialization.serialize_argument(arg).to_json)
      json = send_message("evaluateExpressionHandle", JSON::Any.new(params))
      connection.get_existing_object(json["handle"]["guid"].as_s).as(JSHandleImpl)
    end

    def fill(selector : String, value : String, options : FillOptions?) : Nil
      options ||= FillOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      params["value"] = JSON::Any.new(value)
      send_message("fill", JSON::Any.new(params))
    end

    def focus(selector : String, options : FocusOptions?) : Nil
      options ||= FocusOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      send_message("focus", JSON::Any.new(params))
    end

    def frame_element : ElementHandle
      json = send_message("frameElement")
      connection.get_existing_object(json["element"]["guid"].as_s).as(ElementHandleImpl)
    end

    def get_attribute(selector : String, name : String, options : GetAttributeOptions?) : String?
      options ||= GetAttributeOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      params["name"] = JSON::Any.new(name)
      json = send_message("getAttribute", JSON::Any.new(params))
      json["value"]?.try &.as_s
    end

    def goto(url : String, options : NavigateOptions? = nil) : Response?
      options ||= NavigateOptions.new
      options.wait_until = Frame::LoadState::LOAD if options.wait_until.nil?
      params = JSON.parse(options.to_json).as_h
      params["url"] = JSON::Any.new(url)
      result = send_message("goto", JSON::Any.new(params))
      if resp = result["response"]?
        return connection.get_existing_object(resp["guid"].as_s).as(ResponseImpl)
      end
      nil
    end

    def hover(selector : String, options : HoverOptions?) : Nil
      options ||= HoverOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      send_message("hover", JSON::Any.new(params))
    end

    def inner_html(selector : String, options : InnerHTMLOptions?) : String
      options ||= InnerHTMLOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      send_message("innerHTML", JSON::Any.new(params))["value"].as_s
    end

    def inner_text(selector : String, options : InnerTextOptions?) : String
      options ||= InnerTextOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      send_message("innerText", JSON::Any.new(params))["value"].as_s
    end

    def press(selector : String, key : String, options : PressOptions?) : Nil
      options ||= PressOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      params["key"] = JSON::Any.new(key)
      send_message("press", JSON::Any.new(params))
    end

    def select_option(selector : String, values : Array(ElementHandle::SelectOption)?, options : SelectOptionOptions?)
      options ||= SelectOptionOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      if v = values
        params["options"] = JSON.parse(v.to_json)
      end
      select_option(JSON::Any.new(params))
    end

    def select_option(selector : String, values : Array(ElementHandle)?, options : SelectOptionOptions?)
      options ||= SelectOptionOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      if v = values
        params["elements"] = Serialization.to_protocol(v)
      end
      select_option(JSON::Any.new(params))
    end

    private def select_option(params : JSON::Any)
      json = send_message("selectOption", params)
      Serialization.parse_stringlist(json["values"])
    end

    def set_content(html : String, options : SetContentOptions?) : Nil
      options ||= SetContentOptions.new
      options.wait_until = Frame::LoadState::LOAD if options.wait_until.nil?
      params = JSON.parse(options.to_json).as_h
      params["html"] = JSON::Any.new(html)
      send_message("setContent", JSON::Any.new(params))
    end

    def set_input_files(selector : String, file : Array(Path), options : SetFilesOptions?)
      set_input_files(selector, Utils.to_file_payload(file), options)
    end

    def set_input_files(selector : String, file : Array(FileChooser::FilePayload), options : SetInputFilesOptions?)
      options ||= SetInputFilesOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      params["files"] = Serialization.to_json_array(file)
      send_message("setInputFiles", JSON::Any.new(params))
    end

    def tap(selector : String, options : TapOptions?) : Nil
      options ||= TapOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      send_message("tap", JSON::Any.new(params))
    end

    def text_content(selector : String, options : TextContentOptions?) : String?
      options ||= TextContentOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      send_message("textContent", JSON::Any.new(params))["value"].as_s?
    end

    def title : String
      send_message("title")["value"].as_s
    end

    def type(selector : String, text : String, options : TypeOptions?) : Nil
      options ||= TypeOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      params["text"] = JSON::Any.new(text)
      send_message("type", JSON::Any.new(params))
    end

    def uncheck(selector : String, options : UncheckOptions?) : Nil
      options ||= UncheckOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["selector"] = JSON::Any.new(selector)
      send_message("uncheck", params)
    end

    def wait_for_function(page_function : String, arg : Array(Any)?, options : WaitForFunctionOptions?) : Deferred(JSHandle)
      options ||= WaitForFunctionOptions.new
      params = JSON.parse(options.to_json).as_h
      params["expression"] = JSON::Any.new(page_function)
      params["isFunction"] = JSON::Any.new(function_body?(page_function))
      params["arg"] = JSON.parse(Serialization.serialize_argument(arg).to_json)

      handle = send_message_async("waitForFunction", JSON::Any.new(params)).apply ->(json : JSON::Any) {
        connection.get_existing_object(json["handle"]["guid"].as_s).as(JSHandleImpl).as(JSHandle)
      }
      to_deferred(handle)
    end

    def wait_for_load_state(state : LoadState?, options : WaitForLoadStateOptions?) : Deferred(Nil)
      options ||= WaitForLoadStateOptions.new
      state = state.nil? ? LoadState::LOAD : state.not_nil!

      waitables = Array(Waitable(Nil)).new
      waitables << WaitForLoadStateHelper.new(state, internal_listeners, @load_states).as(Waitable(Nil))
      waitables << PageImpl::WaitablePageClose(Nil).new(@page.not_nil!)
      waitables << CreateWaitable(Nil).new(@page.not_nil!.timeout_settings, options.timeout).get
      to_deferred(WaitableRace(Nil).new(waitables))
    end

    def wait_for_navigation(options : WaitForNavigationOptions?) : Deferred(Response?)
      options ||= WaitForNavigationOptions.new
      options.wait_until = Frame::LoadState::LOAD if options.wait_until.nil?

      waitables = Array(Waitable(Response?)).new
      matcher = UrlMatcher.one_of(options.glob, options.pattern, options.predicate)
      waitables << WaitForNavigationHelper(Response?).new(matcher, options.wait_until.not_nil!, internal_listeners, @load_states, connection)
      waitables << PageImpl::WaitablePageClose(Response?).new(@page.not_nil!)
      waitables << CreateWaitable(Response?).new(@page.not_nil!.timeout_settings, @page.not_nil!.timeout_settings.navigation_timeout(options.timeout || 0)).get
      to_deferred(WaitableRace(Response?).new(waitables))
    end

    def wait_for_selector(selector : String, options : WaitForSelectorOptions?) : Deferred(ElementHandle?)
      options ||= WaitForSelectorOptions.new
      params = JSON.parse(options.to_json).as_h
      params["selector"] = JSON::Any.new(selector)
      handle = send_message_async("waitForSelector", JSON::Any.new(params)).apply ->(json : JSON::Any) {
        if elem = json["element"]?
          return connection.get_existing_object(elem["guid"].as_s).as(ElementHandleImpl).as(ElementHandle)
        end
        nil
      }
      to_deferred(handle)
    end

    def wait_for_timeout(timeout : Int32) : Deferred(Nil)
      to_deferred(WaitableTimeoutHelper.new(timeout))
    end

    def handle_event(event : String, params : JSON::Any)
      if event == "loadstate"
        if add = params["add"]?
          state = LoadState.parse(add.as_s)
          @load_states.add(state)
          internal_listeners.notify(InternalEventType::LOADSTATE, state)
        end
        if rem = params["remove"]?
          @load_states.delete(LoadState.parse(rem.as_s))
        end
      elsif event == "navigated"
        @url = params["url"].as_s
        @name = params["name"].as_s
        if p = page
          p.frame_navigated(self) if !params["error"]?
        end
        internal_listeners.notify(InternalEventType::NAVIGATED, params)
      end
    end

    def parent_frame : Frame?
      @parent_frame
    end

    private class WaitForLoadStateHelper < Waitable(Nil)
      getter expected_state : LoadState
      @event_handler : ListenerImpl(InternalEventType)

      def initialize(@expected_state, @listeners : ListenerCollection(InternalEventType), @load_states : Set(LoadState))
        @is_done = @load_states.includes?(@expected_state)
        @event_handler = ListenerImpl(InternalEventType).new { |event|
          raise "event type : #{event}, expected : loadstate" unless event.type == InternalEventType::LOADSTATE
          if expected_state == event.data
            @is_done = true
            dispose
          end
        }

        @listeners.add(InternalEventType::LOADSTATE, @event_handler) unless @is_done
      end

      def done? : Bool
        @is_done
      end

      def get : Nil
        nil
      end

      def dispose
        @listeners.remove(InternalEventType::LOADSTATE, @event_handler)
      end
    end

    private class WaitForNavigationHelper(T) < Waitable(T)
      getter expected_state : LoadState
      getter matcher : UrlMatcher

      @request : RequestImpl?
      @exception : Exception?
      @load_state_helper : WaitForLoadStateHelper?
      @event_handler : ListenerImpl(InternalEventType)

      def initialize(@matcher, @expected_state, @listeners : ListenerCollection(InternalEventType), @load_states : Set(LoadState), @connection : Connection)
        @event_handler = ListenerImpl(InternalEventType).new { |event|
          raise "event type : #{event.type}, expected : loadstate" unless event.type == InternalEventType::NAVIGATED
          params = event.data.as(JSON::Any)
          next unless matcher.test(params["url"].as_s)
          if err = params["error"]?
            @exception = PlaywrightException.new(err.as_s)
          else
            if nd = params["newDocument"]?
              if req = nd["request"]?
                @request = @connection.get_existing_object(req["guid"].as_s).as(RequestImpl)
              end
            end
            @load_state_helper = WaitForLoadStateHelper.new(expected_state, @listeners, @load_states)
          end
          remove_event()
        }
        @listeners.add(InternalEventType::NAVIGATED, @event_handler)
      end

      def remove_event
        @listeners.remove(InternalEventType::NAVIGATED, @event_handler)
      end

      def done? : Bool
        return true if @exception
        return (@load_state_helper.try &.done? || false) if @load_state_helper
        false
      end

      def get : T
        raise @exception.not_nil! if @exception
        return nil if @request.nil?
        @request.not_nil!.final_request.response
      end

      def dispose
        remove_event
        if dsh = @load_state_helper
          dsh.dispose
        end
      end
    end

    private class WaitableTimeoutHelper < WaitableTimeout(Nil)
      def get : Nil
        nil
      end
    end
  end
end
