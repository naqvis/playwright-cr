require "path"
require "json"

module Playwright
  # Whenever a network route is set up with `page.route(url, handler)` or `browserContext.route(url, handler)`, the `Route` object allows to handle the route.
  module Route
    class ContinueOverrides
      include JSON::Serializable
      # If set changes the request URL. New URL must have same protocol as original one.
      @[JSON::Field(key: "url")]
      property url : String?
      # If set changes the request method (e.g. GET or POST)
      @[JSON::Field(key: "method")]
      property method : String?
      # If set changes the post data of request
      @[JSON::Field(key: "postData")]
      property post_data : Bytes?
      # If set changes the request HTTP headers. Header values will be converted to a string.
      @[JSON::Field(key: "headers")]
      property headers : Hash(String, String)?

      def initialize(@url = nil, @method = nil, @post_data = nil, @headers = nil)
      end

      def with_post_data(data : String)
        self.post_data = data.to_slice
        self
      end
    end

    class FulfillResponse
      include JSON::Serializable
      # Response status code, defaults to `200`.
      @[JSON::Field(key: "status")]
      property status : Int32?
      # Optional response headers. Header values will be converted to a string.
      @[JSON::Field(key: "headers")]
      property headers : Hash(String, String)?
      # If set, equals to setting `Content-Type` response header.
      @[JSON::Field(key: "contentType")]
      property content_type : String?
      # Optional response body.

      @[JSON::Field(ignore: true)]
      property body : String = ""
      @[JSON::Field(ignore: true)]
      property body_bytes : Bytes = Bytes.empty

      # Optional file path to respond with. The content type will be inferred from file extension. If `path` is a relative path, then it is resolved relative to the current working directory.
      @[JSON::Field(key: "path")]
      property path : Path?

      def initialize(@status = nil, @headers = nil, @content_type = nil, @body = nil, @path = nil)
      end
    end

    def abort : Nil
      abort(nil)
    end

    # Aborts the route's request.
    abstract def abort(error_code : String?) : Nil

    def continue : Nil
      continue(nil)
    end

    # Continues route's request with optional overrides.
    #
    abstract def continue(overrides : ContinueOverrides?) : Nil
    # Fulfills route's request with given response.
    # An example of fulfilling all requests with 404 responses:
    #
    # An example of serving static file:
    #
    abstract def fulfill(response : FulfillResponse) : Nil
    # A request to be routed.
    abstract def request : Request
  end
end
