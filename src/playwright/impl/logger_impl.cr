require "json"
require "../logger"

module Playwright
  private class LogerImpl
    include Logger
    include JSON::Serializable

    def is_enabled(_name : String, _severity : Severity) : Bool
      false
    end

    def log(_name : String, _severity : Severity, _message : String, _args : Array(Any), _hints : LogHints) : Nil
      raise "Not Implemented"
    end
  end
end
