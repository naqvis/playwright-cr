require "./jshandle_impl"
require "../elementhandle"

module Playwright
  private class ElementHandleImpl < JSHandleImpl
    include ElementHandle

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
    end

    def as_element : ElementHandle?
      self
    end

    def query_selector(selector : String) : ElementHandle?
      json = send_message("querySelector", JSON::Any.new({"selector" => JSON::Any.new(selector)}))
      return nil unless json["element"]?
      connection.get_existing_object(json["element"]["guid"].as_s).as(ElementHandleImpl)
    end

    def query_selector_all(selector : String) : Array(ElementHandle)
      json = send_message("querySelectorAll", JSON::Any.new({"selector" => JSON::Any.new(selector)}))
      handles = Array(ElementHandle).new
      return handles unless json["elements"]?
      json["elements"].as_a.each do |e|
        handles << connection.get_existing_object(e["guid"].as_s).as(ElementHandleImpl)
      end
      handles
    end

    def eval_on_selector(selector : String, page_function : String, arg : Array(Any)?) : Any
      params = {
        "selector"   => JSON::Any.new(selector),
        "expression" => JSON::Any.new(page_function),
        "isFunction" => JSON::Any.new(function_body?(arg)),
        "arg"        => JSON.parse(Serialization.serialize_argument(arg).to_json),
      } of String => JSON::Any

      json = send_message("evalOnSelector", JSON::Any.new(params))
      Serialization.deserialize(SerializationValue.from_json(json["value"].to_json))
    end

    def eval_on_selector_all(selector : String, page_function : String, arg : Array(Any)?) : Any
      params = {
        "selector"   => JSON::Any.new(selector),
        "expression" => JSON::Any.new(page_function),
        "isFunction" => JSON::Any.new(function_body?(page_function)),
        "arg"        => JSON.parse(Serialization.serialize_argument(arg).to_json),
      } of String => JSON::Any

      json = send_message("evalOnSelectorAll", JSON::Any.new(params))
      Serialization.deserialize(SerializationValue.from_json(json["value"].to_json))
    end

    def bounding_box : BoundingBox?
      json = send_message("boundingBox")
      return nil unless json["value"]?
      BoundingBox.from_json(json["value"].to_json)
    end

    def check(options : CheckOptions?) : Nil
      options ||= CheckOptions.new
      send_message("check", JSON.parse(options.to_json))
    end

    def click(options : ClickOptions?) : Nil
      options ||= ClickOptions.new
      send_message("click", JSON.parse(options.to_json))
    end

    def content_frame : Frame?
      json = send_message("contentFrame")
      return nil unless json["frame"]?
      connection.get_existing_object(json["frame"]["guid"].as_s).as(FrameImpl)
    end

    def dblclick(options : DblclickOptions?) : Nil
      options ||= DblclickOptions.new
      send_message("dblclick", JSON.parse(options.to_json))
    end

    def dispatch_event(type : String, event_init : Array(Any)?) : Nil
      params = {
        "type"      => JSON::Any.new(type),
        "eventInit" => JSON.parse(Serialization.serialize_argument(event_init).to_json),
      } of String => JSON::Any
      send_message("dispatchEvent", JSON::Any.new(params))
    end

    def fill(value : String, options : FillOptions?) : Nil
      options ||= FillOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["value"] = JSON::Any.new(value)
      send_message("fill", params)
    end

    def focus : Nil
      send_message("focus")
    end

    def get_attribute(name : String) : String?
      json = send_message("getAttribute", JSON::Any.new({"name" => JSON::Any.new(name)}))
      json["value"]?.try &.as_s?
    end

    def hover(options : HoverOptions?) : Nil
      options ||= HoverOptions.new
      send_message("hover", JSON.parse(options.to_json))
    end

    def inner_html : String
      send_message("innerHTML")["value"].as_s
    end

    def inner_text : String
      send_message("innerText")["value"].as_s
    end

    def owner_frame : Frame?
      json = send_message("ownerFrame")
      return nil unless json["frame"]?
      connection.get_existing_object(json["frame"]["guid"].as_s).as(FrameImpl)
    end

    def press(key : String, options : PressOptions?) : Nil
      options ||= PressOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["key"] = JSON::Any.new(key)
      send_message("press", params)
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

      params = JSON.parse(options.to_json)
      params.as_h.delete("path")
      json = send_message("screenshot", params)

      buffer = Base64.decode(json["binary"].as_s)
      File.write(options.path.not_nil!, buffer) if options.path
      buffer
    end

    def scroll_into_view_if_needed(options : ScrollIntoViewIfNeededOptions?) : Nil
      options ||= ScrollIntoViewIfNeededOptions.new
      send_message("scrollIntoViewIfNeeded", JSON.parse(options.to_json))
    end

    def select_option(values : Array(SelectOption)?, options : SelectOptionOptions?)
      options ||= SelectOptionOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["options"] = JSON.parse(values.not_nil!.to_json)
      select_option(params)
    end

    def select_option(values : Array(ElementHandle)?, options : SelectOptionOptions?)
      options ||= SelectOptionOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["elements"] = Serialization.to_protocol(values.not_nil_) if values
      select_option(params)
    end

    def select_text(options : SelectTextOptions?) : Nil
      options ||= SelectTextOptions.new
      send_message("selectText", JSON.parse(options.to_json))
    end

    def set_input_files(file : Array(FileChooser::FilePayload), options : SetInputFilesOptions?)
      options ||= SetInputFilesOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["files"] = Serialization.to_json_array(file)
      send_message("setInputFiles", params)
    end

    def set_input_files(file : Array(Path), options : SetInputFilesOptions?)
      set_input_files(Utils.to_file_payload(file), options)
    end

    def tap(_options : TapOptions?) : Nil
    end

    def text_content : String?
      send_message("textContent")["value"]?.try &.as_s?
    end

    def to_string : String
    end

    def type(text : String, options : TypeOptions?) : Nil
      options ||= TypeOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["text"] = JSON::Any.new(text)
      send_message("type", params)
    end

    def uncheck(options : UncheckOptions?) : Nil
      options ||= UncheckOptions.new
      send_message("uncheck", JSON.parse(options.to_json))
    end

    def wait_for_element_state(state : ElementState, options : WaitForElementStateOptions?) : Deferred(Nil)
      options ||= WaitForElementStateOptions.new
      params = JSON.parse(options.to_json)
      params.as_h["state"] = JSON::Any.new(state.to_s)
      DeferredImpl.new(send_message_async("waitForElementState", params), connection)
    end

    def wait_for_selector(selector : String, options : WaitForSelectorOptions?) : Deferred(ElementHandle?)
      options ||= WaitForSelectorOptions.new
      options.state = WaitForElementStateOptions::State::VISIBLE if options.state.nil?
      params = JSON.parse(options.to_json)
      params.as_h["state"] = JSON::Any.new(option.state.to_s)
      params.as_h["selector"] = JSON::Any.new(selector)
      DeferredImpl.new(send_message_async("waitForElementState", params), connection)
    end

    def create_selector_for_test(name : String)
      params = {"name" => JSON::Any.new(name)}
      json = send_message("createSelectorForTest", JSON::Any.new(params))
      json["value"]?.try &.as_s?
    end

    private def select_option(params)
      json = send_message("selectOption", params)
      Serialization.parse_stringlist(json)
    end

    private struct DeferredImpl < Deferred(Nil)
      def initialize(@waitable : Waitable(JSON::Any), @connection : Connection)
      end

      def get : Nil
        while (!@waitable.done?)
          @connection.process_one_message
        end
        @waitable.get
      end
    end
  end
end
