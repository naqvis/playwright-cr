require "json"

module Playwright
  # The WebSocket class represents websocket connections in the page.
  module WebSocket
    module FrameData
      abstract def body : Bytes
      abstract def text : String
    end

    class WaitForEventOptions
      property timeout : Int32?
      property predicate : ((Event(EventType)) -> Bool) | Nil

      def initialize(@timeout = nil, @predicate = nil)
      end
    end

    enum EventType
      CLOSE
      FRAMERECEIVED
      FRAMESENT
      SOCKETERROR
    end

    abstract def add_listener(type : EventType, listener : Listener(EventType))
    abstract def remove_listener(type : EventType, listener : Listener(EventType))
    # Indicates that the web socket has been closed.
    abstract def is_closed : Bool
    # Contains the URL of the WebSocket.
    abstract def url : String

    def wait_for_event(event : EventType) : Deferred(Event(EventType))
      wait_for_event(event, nil)
    end

    def wait_for_event(event : EventType, predicate : ((Event(EventType)) -> Bool)) : Deferred(Event(EventType))
      options = WaitForEventOptions.new
      options.predicate = predicate
      wait_for_event(event, options)
    end

    # Returns the event data value.
    # Waits for event to fire and passes its value into the predicate function. Returns when the predicate returns truthy value. Will throw an error if the webSocket is closed before the event is fired.
    abstract def wait_for_event(event : EventType, options : WaitForEventOptions?) : Deferred(Event(EventType))
  end
end
