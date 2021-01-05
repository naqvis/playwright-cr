require "json"

module Playwright
  # The Worker class represents a WebWorker. `worker` event is emitted on the page object to signal a worker creation. `close` event is emitted on the worker object when the worker is gone.
  #
  module Worker
    enum EventType
      CLOSE
    end

    abstract def add_listener(type : EventType, listener : Listener(EventType))
    abstract def remove_listener(type : EventType, listener : Listener(EventType))

    def evaluate(page_function : String) : Any
      evaluate(page_function, nil)
    end

    def evaluate(page_function : String, *arg : Any) : Any
      evaluate(page_function, arg.to_a)
    end

    # Returns the return value of `pageFunction`
    # If the function passed to the `worker.evaluate` returns a Promise, then `worker.evaluate` would wait for the promise to resolve and return its value.
    # If the function passed to the `worker.evaluate` returns a non-Serializable value, then `worker.evaluate` returns `undefined`. DevTools Protocol also supports transferring some additional values that are not serializable by `JSON`: `-0`, `NaN`, `Infinity`, `-Infinity`, and bigint literals.
    abstract def evaluate(page_function : String, arg : Array(Any)?) : Any

    def evaluate_handle(page_function : String) : JSHandle
      evaluate_handle(page_function, nil)
    end

    def evaluate_handle(page_function : String, *arg : Any) : JSHandle
      evaluate_handle(page_function, arg.to_a)
    end

    # Returns the return value of `pageFunction` as in-page object (JSHandle).
    # The only difference between `worker.evaluate` and `worker.evaluateHandle` is that `worker.evaluateHandle` returns in-page object (JSHandle).
    # If the function passed to the `worker.evaluateHandle` returns a Promise, then `worker.evaluateHandle` would wait for the promise to resolve and return its value.
    abstract def evaluate_handle(page_function : String, arg : Array(Any)?) : JSHandle
    abstract def url : String
    abstract def wait_for_event(event : EventType) : Deferred(Event(EventType))
  end
end
