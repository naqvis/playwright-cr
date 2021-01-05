require "json"

module Playwright
  # JSHandle represents an in-page JavaScript object. JSHandles can be created with the `page.evaluateHandle(pageFunction[, arg])` method.
  #
  # JSHandle prevents the referenced JavaScript object being garbage collected unless the handle is exposed with `jsHandle.dispose()`. JSHandles are auto-disposed when their origin frame gets navigated or the parent context gets destroyed.
  # JSHandle instances can be used as an argument in `page.$eval(selector, pageFunction[, arg])`, `page.evaluate(pageFunction[, arg])` and `page.evaluateHandle(pageFunction[, arg])` methods.
  module JSHandle
    # Returns either `null` or the object handle itself, if the object handle is an instance of ElementHandle.
    abstract def as_element : ElementHandle?
    # The `jsHandle.dispose` method stops referencing the element handle.
    abstract def dispose : Nil

    def evaluate(page_function : String) : Any
      evaluate(page_function, nil)
    end

    def evaluate(page_function : String, *arg : Any) : Any
      evaluate(page_function, arg.to_a)
    end

    # Returns the return value of `pageFunction`
    # This method passes this handle as the first argument to `pageFunction`.
    # If `pageFunction` returns a Promise, then `handle.evaluate` would wait for the promise to resolve and return its value.
    # Examples:
    #
    abstract def evaluate(page_function : String, arg : Array(Any)?) : Any

    def evaluate_handle(page_function : String) : JSHandle
      evaluate_handle(page_function, nil)
    end

    def evaluate_handle(page_function : String, *arg : Any) : JSHandle
      evaluate_handle(page_function, arg.to_a)
    end

    # Returns the return value of `pageFunction` as in-page object (JSHandle).
    # This method passes this handle as the first argument to `pageFunction`.
    # The only difference between `jsHandle.evaluate` and `jsHandle.evaluateHandle` is that `jsHandle.evaluateHandle` returns in-page object (JSHandle).
    # If the function passed to the `jsHandle.evaluateHandle` returns a Promise, then `jsHandle.evaluateHandle` would wait for the promise to resolve and return its value.
    # See `page.evaluateHandle(pageFunction[, arg])` for more details.
    abstract def evaluate_handle(page_function : String, arg : Array(Any)?) : JSHandle
    # The method returns a map with **own property names** as keys and JSHandle instances for the property values.
    #
    abstract def get_properties : Hash(String, JSHandle)
    # Fetches a single property from the referenced object.
    abstract def get_property(property_name : String) : JSHandle
    # Returns a JSON representation of the object. If the object has a `toJSON` function, it **will not be called**.
    #
    # **NOTE** The method will return an empty JSON object if the referenced object is not stringifiable. It will throw an error if the object has circular references.
    abstract def json_value : Any
  end
end
