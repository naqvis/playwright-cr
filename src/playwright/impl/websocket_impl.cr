require "./channel_owner"
require "../websocket"

module Playwright
  private class WebSocketImpl < ChannelOwner
    include WebSocket

    private getter page : PageImpl
    getter is_closed : Bool = false
    private getter listeners : ListenerCollection(EventType)

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
      @listeners = ListenerCollection(EventType).new
      @page = parent.as(PageImpl)
    end

    def add_listener(type : EventType, listener : Listener(EventType))
      listeners.add(type, listener)
    end

    def remove_listener(type : EventType, listener : Listener(EventType))
      listeners.remove(type, listener)
    end

    def url : String
      jsinitializer["url"].as_s
    end

    def wait_for_event(event : EventType, options : WaitForEventOptions?) : Deferred(Event(EventType))
      options ||= WaitForEventOptions.new

      waitables = Array(Waitable(Event(EventType))).new
      waitables << WaitableEvent(EventType).new(listeners, event, options.predicate)
      waitables << WaitableWebSocketError(Event(EventType)).new(self)
      waitables << PageImpl::WaitablePageClose(Event(EventType)).new(page)
      waitables << CreateWaitable(Event(EventType)).new(page.timeout_settings, options.timeout).get

      to_deferred(WaitableRace(Event(EventType)).new(waitables))
    end

    def handle_event(event : String, params : JSON::Any)
      case event
      when "frameSent"
        frame_data = FrameDataImpl.new(params["data"].as_s, params["opcode"].as_i == 2)
        listeners.notify(EventType::FRAMESENT, frame_data)
      when "frameReceived"
        frame_data = FrameDataImpl.new(params["data"].as_s, params["opcode"].as_i == 2)
        listeners.notify(EventType::FRAMERECEIVED, frame_data)
      when "socketError"
        error = params["error"].as_s
        listeners.notify(EventType::SOCKETERROR, error)
      when "close"
        @is_closed = true
        listeners.notify(EventType::CLOSE, nil)
      else
        raise PlaywrightException.new("Uknown event: #{event}")
      end
    end

    private class FrameDataImpl
      include WebSocket::FrameData
      getter body : Bytes

      def initialize(payload : String, is_base64 : Bool)
        @body = is_base64 ? Base64.decode(payload) : payload.to_slice
      end

      def text : String
        String.new(body)
      end
    end

    private class WaitableWebSocketError(R) < Waitable(R)
      getter subscribed_events : Array(EventType)

      def initialize(@page : WebSocketImpl)
        @error_message = ""
        @subscribed_events = [EventType::CLOSE, EventType::SOCKETERROR]
        @event_handler = ListenerImpl(EventType).new { |event|
          case event.type
          when .socketerror? then @error_message = "Socket error"
          when .close?       then @error_message = "Socket closed"
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
  end
end
