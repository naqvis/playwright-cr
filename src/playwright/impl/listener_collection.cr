require "./waitable"

module Playwright
  private class ListenerCollection(T)
    getter callbacks : Hash(T, Array(ListenerImpl(T)))

    def initialize
      @callbacks = Hash(T, Array(ListenerImpl(T))).new { |hash, key| hash[key] = Array(ListenerImpl(T)).new }
    end

    def notify(type : T, param : Any)
      return if callbacks.empty?
      list = callbacks[type]
      return if list.empty?
      event = EventImpl(T).new(type, param).as(Event(T))
      list.each { |e| e.handle(event) }
    end

    def add(type : T, listener : ListenerImpl(T))
      callbacks[type].push(listener)
    end

    def remove(type : T, listener : ListenerImpl(T))
      list = callbacks[type]?
      return if list.nil?
      list.delete(listener)
      callbacks.delete(type) if list.empty?
    end

    def has_listeners(type : T)
      callbacks.has_key?(type)
    end
  end

  private class EventImpl(T)
    include Event(T)

    def initialize(@type : T, @param : Any)
    end

    def type : T
      @type
    end

    def data : Any
      @param
    end
  end
end
