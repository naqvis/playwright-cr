require "json"

module Playwright
  # Response class represents responses which are received by page.
  module Response
    # Returns the buffer with response body.
    abstract def body : Bytes
    # Waits for this response to finish, returns failure error if request failed.
    abstract def finished : String?
    # Returns the Frame that initiated this response.
    abstract def frame : Frame
    # Returns the object with HTTP headers associated with the response. All header names are lower-case.
    abstract def headers : Hash(String, String)
    # Contains a boolean stating whether the response was successful (status in the range 200-299) or not.
    abstract def ok : Bool
    # Returns the matching Request object.
    abstract def request : Request
    # Contains the status code of the response (e.g., 200 for a success).
    abstract def status : Int32
    # Contains the status text of the response (e.g. usually an "OK" for a success).
    abstract def status_text : String
    # Returns the text representation of response body.
    abstract def text : String
    # Contains the URL of the response.
    abstract def url : String
  end
end
