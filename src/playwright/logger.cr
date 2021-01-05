require "json"

module Playwright
  # Playwright generates a lot of logs and they are accessible via the pluggable logger sink.
  #
  module Logger
    enum Severity
      ERROR
      INFO
      VERBOSE
      WARNING

      def to_s
        super.downcase
      end

      def to_json(json : JSON::Builder)
        json.string(to_s)
      end
    end

    class LogHints
      include JSON::Serializable
      # preferred logger color
      @[JSON::Field(key: "color")]
      property color : String?

      def initialize(@color = nil)
      end
    end

    # Determines whether sink is interested in the logger with the given name and severity.
    abstract def is_enabled(name : String, severity : Severity) : Bool
    abstract def log(name : String, severity : Severity, message : String, args : Array(Any), hints : LogHints) : Nil
  end
end
