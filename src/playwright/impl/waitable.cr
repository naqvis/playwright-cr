module Playwright
  abstract struct Deferred(T)
    abstract def get : T
  end

  abstract class Waitable(T)
    abstract def done? : Bool
    abstract def get : T

    def dispose
    end

    def apply(transform : T -> U) : Waitable(U) forall U
      WaitableAdapter(T, U).new(self, transform).as(Waitable(U))
    end
  end

  module Listener(EventType)
    abstract def handle(_event : Event(EventType))
  end

  module Event(EventType)
    abstract def type : EventType
    abstract def data : Any
  end

  class ListenerImpl(T)
    include Listener(T)

    @func : Event(T) ->

    def initialize(&block : Event(T) ->)
      @func = block
    end

    def handle(event : Event(T))
      @func.call(event)
    end
  end

  private class WaitableAdapter(F, T) < Waitable(T)
    @waitable : Waitable(F)
    @transformation : Proc(F, T)

    def initialize(@waitable, @transformation)
    end

    def done? : Bool
      @waitable.done?
    end

    def get : T
      @transformation.call(@waitable.get.as(F))
    end
  end

  private class WaitableResult(T) < Waitable(T)
    @is_done : Bool = false
    @result : T?
    @exception : Exception?

    def complete(result : T)
      return if @is_done
      @result = result
      @is_done = true
    end

    def complete_exceptionally(excp : Exception)
      @exception = excp
    end

    def done? : Bool
      @is_done
    end

    def get : T
      raise PlaywrightException.new(@exception.try &.message || "") unless @exception.nil?
      raise PlaywrightException.new("result is nil") unless @result
      @result.not_nil!
    end
  end

  private class WaitableNever(T) < Waitable(T)
    def done? : Bool
      false
    end

    def get : T
      raise PlaywrightException.new("Should never be called")
    end
  end

  private class WaitableTimeout(T) < Waitable(T)
    @deadline : Float64

    def initialize(@timeout : Int32)
      @deadline = Time.monotonic.total_nanoseconds + @timeout.to_f64 * 1_000_000
    end

    def done? : Bool
      Time.monotonic.total_nanoseconds > @deadline
    end

    def get : T
      raise PlaywrightException.new("Timeout #{@timeout} ms exceeded")
    end
  end

  private class WaitableEvent(EventType) < Waitable(Event(EventType))
    getter listeners : ListenerCollection(EventType)
    @type : EventType
    getter predicate : (Event(EventType) -> Bool)?
    getter event : Event(EventType)?
    @event_handler : ListenerImpl(EventType)

    def initialize(@listeners, @type, @predicate = nil)
      @event_handler = ListenerImpl(EventType).new { |event|
        raise PlaywrightException.new("event type: #{event.type} does match expected type: #{@type}") unless @type == event.type
        if p = @predicate
          next unless p.call(event)
        end
        @event = event
      }
      @listeners.add(@type, @event_handler)
    end

    def done? : Bool
      !event.nil?
    end

    def get : Event(EventType)
      event.not_nil!
    end

    def dispose
      listeners.remove(@type, @event_handler)
    end
  end

  private class WaitableRace(T) < Waitable(T)
    private getter waitables : Array(Waitable(T))

    def initialize(values)
      @waitables = values
    end

    def done? : Bool
      waitables.each do |w|
        return true if w.done?
      end
      false
    end

    def get : T
      raise PlaywrightException.new("Waitable not completed") unless done?
      dispose
      waitables.each do |w|
        return w.get if w.done?
      end
      raise ArgumentError.new("At least one element must be ready")
    end

    def dispose
      waitables.each do |w|
        w.dispose
      end
    end
  end

  private class CreateWaitable(T)
    def initialize(@settings : TimeoutSettings, @timeout : Int32?)
    end

    def get : Waitable(T)
      if t = @timeout
        return WaitableNever(T).new if t == 0
      end
      WaitableTimeout(T).new(@settings.timeout(@timeout))
    end
  end
end
