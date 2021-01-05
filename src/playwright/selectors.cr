require "path"
require "json"

module Playwright
  # Selectors can be used to install custom selector engines. See Working with selectors for more information.
  module Selectors
    class RegisterOptions
      include JSON::Serializable
      # Whether to run this selector engine in isolated JavaScript environment. This environment has access to the same DOM, but not any JavaScript objects from the frame's scripts. Defaults to `false`. Note that running as a content script is not guaranteed when this engine is used together with other registered engines.
      @[JSON::Field(key: "contentScript")]
      property content_script : Bool?

      def initialize(@content_script = nil)
      end
    end

    def register(name : String, script : String)
      register(name, script, nil)
    end

    abstract def register(name : String, script : String, options : RegisterOptions?)

    def register(name : String, path : Path)
      register(name, path, nil)
    end

    # An example of registering selector engine that queries elements based on a tag name:
    #

    abstract def register(name : String, path : Path, options : RegisterOptions?)
  end
end
