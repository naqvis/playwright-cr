require "base64"
require "./channel_owner"
require "./request_impl"
require "../response"

module Playwright
  private class ResponseImpl < ChannelOwner
    include Response

    getter headers : Hash(String, String)
    private getter request : RequestImpl

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)

      @headers = Hash(String, String).new
      jsinitializer["headers"].as_a.each do |e|
        @headers[e["name"].as_s.downcase] = e["value"].as_s
      end
      @request = connection.get_existing_object(jsinitializer["request"]["guid"].as_s).as(RequestImpl)

      @request.headers.clear
      jsinitializer["requestHeaders"].as_a.each do |e|
        @request.headers[e["name"].as_s.downcase] = e["value"].as_s
      end
    end

    def body : Bytes
      json = send_message("body")
      Base64.decode(json["binary"].as_s)
    end

    def finished : String?
      json = send_message("body")
      json["error"].as_s?
    end

    def frame : Frame
      request.frame
    end

    def ok : Bool
      status == 0 || (status >= 200 && status <= 299)
    end

    def request : Request
      @request
    end

    def status : Int32
      jsinitializer["status"].as_i
    end

    def status_text : String
      jsinitializer["statusText"].as_s
    end

    def text : String
      String.new(body)
    end

    def url : String
      jsinitializer["url"].as_s
    end
  end
end
