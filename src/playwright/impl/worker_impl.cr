require "./channel_owner"
require "../worker"

module Playwright
  private class WorkerImpl < ChannelOwner
    include Worker
    private getter listeners : ListenerCollection(EventType)
    property page : PageImpl?

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
      @listeners = ListenerCollection(EventType).new
    end

    def add_listener(type : EventType, listener : Listener(EventType))
      listeners.add(type, listener)
    end

    def remove_listener(type : EventType, listener : Listener(EventType))
      listeners.remove(type, listener)
    end

    def evaluate(page_function : String, arg : Array(Any)?) : Any
      params = {
        "expression" => JSON::Any.new(page_function),
        "isFunction" => JSON::Any.new(function_body?(page_function)),
        "arg"        => JSON.parse(Serialization.serialize_argument(arg).to_json),
      } of String => JSON::Any

      json = send_message("evaluateExpression", JSON::Any.new(params))
      Serialization.deserialize(SerializedValue.from_json(json["value"].to_json))
    end

    def evaluate_handle(page_function : String, arg : Array(Any)?) : JSHandle
      params = {
        "expression" => JSON::Any.new(page_function),
        "isFunction" => JSON::Any.new(function_body?(page_function)),
        "arg"        => JSON.parse(Serialization.serialize_argument(arg).to_json),
      } of String => JSON::Any

      json = send_message("evaluateExpressionHandle", JSON::Any.new(params))
      connection.get_existing_object(json["handle"]["guid"].as_s).as(JSHandleImpl)
    end

    def url : String
      jsinitializer["url"].as_s
    end

    def wait_for_event(event : EventType) : Deferred(Event(EventType))
      to_deferred(WaitableEvent(EventType).new(listeners, event))
    end

    def handle_event(event : String, _params : JSON::Any)
      if event == "close"
        if p = page
          p.delete_worker(self)
        end
        listeners.notify(EventType::CLOSE, self)
      end
    end
  end
end
