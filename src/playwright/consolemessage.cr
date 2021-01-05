require "json"

module Playwright
  # ConsoleMessage objects are dispatched by page via the page.on('console') event.
  module ConsoleMessage
    class Location
      include JSON::Serializable
      # URL of the resource if available, otherwise empty string.
      @[JSON::Field(key: "url")]
      getter url : String
      # 0-based line number in the resource.
      @[JSON::Field(key: "lineNumber")]
      getter line_number : Int32
      # 0-based column number in the resource.
      @[JSON::Field(key: "columnNumber")]
      getter column_number : Int32

      def initialize(@url, @line_number, @column_number)
      end
    end

    abstract def args : Array(JSHandle)
    abstract def location : Location
    abstract def text : String
    # One of the following values: `'log'`, `'debug'`, `'info'`, `'error'`, `'warning'`, `'dir'`, `'dirxml'`, `'table'`, `'trace'`, `'clear'`, `'startGroup'`, `'startGroupCollapsed'`, `'endGroup'`, `'assert'`, `'profile'`, `'profileEnd'`, `'count'`, `'timeEnd'`.
    abstract def type : String
  end
end
