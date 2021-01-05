require "json"

module Playwright
  # Whenever the page sends a request for a network resource the following sequence of events are emitted by Page:
  #
  # page.on('request') emitted when the request is issued by the page.
  # page.on('response') emitted when/if the response status and headers are received for the request.
  # page.on('requestfinished') emitted when the response body is downloaded and the request is complete.
  #
  # If request fails at some point, then instead of `'requestfinished'` event (and possibly instead of 'response' event), the  page.on('requestfailed') event is emitted.
  #
  # **NOTE** HTTP Error responses, such as 404 or 503, are still successful responses from HTTP standpoint, so request will complete with `'requestfinished'` event.
  #
  # If request gets a 'redirect' response, the request is successfully finished with the 'requestfinished' event, and a new request is  issued to a redirected url.
  module Request
    class RequestFailure
      include JSON::Serializable
      # Human-readable error message, e.g. `'net::ERR_FAILED'`.
      @[JSON::Field(key: "errorText")]
      getter error_text : String

      def initialize(@error_text)
      end
    end

    class RequestTiming
      include JSON::Serializable
      # Request start time in milliseconds elapsed since January 1, 1970 00:00:00 UTC
      @[JSON::Field(key: "startTime")]
      getter start_time : Int32
      # Time immediately before the browser starts the domain name lookup for the resource. The value is given in milliseconds relative to `startTime`, -1 if not available.
      @[JSON::Field(key: "domainLookupStart")]
      getter domain_lookup_start : Int32
      # Time immediately after the browser starts the domain name lookup for the resource. The value is given in milliseconds relative to `startTime`, -1 if not available.
      @[JSON::Field(key: "domainLookupEnd")]
      getter domain_lookup_end : Int32
      # Time immediately before the user agent starts establishing the connection to the server to retrieve the resource. The value is given in milliseconds relative to `startTime`, -1 if not available.
      @[JSON::Field(key: "connectStart")]
      getter connect_start : Int32
      # Time immediately before the browser starts the handshake process to secure the current connection. The value is given in milliseconds relative to `startTime`, -1 if not available.
      @[JSON::Field(key: "secureConnectionStart")]
      getter secure_connection_start : Int32
      # Time immediately before the user agent starts establishing the connection to the server to retrieve the resource. The value is given in milliseconds relative to `startTime`, -1 if not available.
      @[JSON::Field(key: "connectEnd")]
      getter connect_end : Int32
      # Time immediately before the browser starts requesting the resource from the server, cache, or local resource. The value is given in milliseconds relative to `startTime`, -1 if not available.
      @[JSON::Field(key: "requestStart")]
      getter request_start : Int32
      # Time immediately after the browser starts requesting the resource from the server, cache, or local resource. The value is given in milliseconds relative to `startTime`, -1 if not available.
      @[JSON::Field(key: "responseStart")]
      getter response_start : Int32
      # Time immediately after the browser receives the last byte of the resource or immediately before the transport connection is closed, whichever comes first. The value is given in milliseconds relative to `startTime`, -1 if not available.
      @[JSON::Field(key: "responseEnd")]
      getter response_end : Int32

      def initialize(@start_time, @domain_lookup_start, @domain_lookup_end, @connect_start, @secure_connection_start, @connect_end, @request_start, @response_start, @response_end)
      end
    end

    # The method returns `null` unless this request has failed, as reported by `requestfailed` event.
    # Example of logging of all the failed requests:
    #
    abstract def failure : RequestFailure?
    # Returns the Frame that initiated this request.
    abstract def frame : Frame
    # An object with HTTP headers associated with the request. All header names are lower-case.
    abstract def headers : Hash(String, String)
    # Whether this request is driving frame's navigation.
    abstract def is_navigation_request : Bool
    # Request's method (GET, POST, etc.)
    abstract def method : String
    # Request's post body, if any.
    abstract def post_data : String?
    # Request's post body in a binary form, if any.
    abstract def post_data_buffer : Bytes?
    # Request that was redirected by the server to this one, if any.
    # When the server responds with a redirect, Playwright creates a new Request object. The two requests are connected by `redirectedFrom()` and `redirectedTo()` methods. When multiple server redirects has happened, it is possible to construct the whole redirect chain by repeatedly calling `redirectedFrom()`.
    # For example, if the website `http://example.com` redirects to `https://example.com`:
    #
    # If the website `https://google.com` has no redirects:
    #
    abstract def redirected_from : Request?
    # New request issued by the browser if the server responded with redirect.
    # This method is the opposite of `request.redirectedFrom()`:
    #
    abstract def redirected_to : Request?
    # Contains the request's resource type as it was perceived by the rendering engine. ResourceType will be one of the following: `document`, `stylesheet`, `image`, `media`, `font`, `script`, `texttrack`, `xhr`, `fetch`, `eventsource`, `websocket`, `manifest`, `other`.
    abstract def resource_type : String
    # Returns the matching Response object, or `null` if the response was not received due to error.
    abstract def response : Response?
    # Returns resource timing information for given request. Most of the timing values become available upon the response, `responseEnd` becomes available when request finishes. Find more information at Resource Timing API.
    #
    abstract def timing : RequestTiming
    # URL of the request.
    abstract def url : String
  end
end
