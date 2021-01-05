require "base64"
require "./channel_owner"
require "../request"

module Playwright
  private class RequestImpl < ChannelOwner
    include Request

    getter headers : Hash(String, String)
    @redirected_from : RequestImpl?
    getter(redirected_to : RequestImpl?) { @redirected_from.nil? ? nil : self }
    @post_data : Bytes?
    property! failure : RequestFailure

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)

      @headers = Hash(String, String).new
      jsinitializer["headers"].as_a.each do |e|
        @headers[e["name"].as_s.downcase] = e["value"].as_s
      end

      if rf = jsinitializer["redirectedFrom"]?
        @redirected_from = connection.get_existing_object(rf["guid"].as_s).as(RequestImpl)
      end

      if rf = jsinitializer["postData"]?
        @post_data = Base64.decode(rf.as_s)
      end
    end

    def failure : RequestFailure?
      failure
    end

    def frame : Frame
      connection.get_existing_object(jsinitializer["frame"]["guid"].as_s).as(FrameImpl)
    end

    def is_navigation_request : Bool
      jsinitializer["isNavigationRequest"].as_bool
    end

    def method : String
      jsinitializer["method"].as_s
    end

    def post_data : String?
      @post_data.nil? ? nil : String.new(@post_data.not_nil!)
    end

    def post_data_buffer : Bytes?
      @post_data
    end

    def redirected_from : Request?
      @redirected_from
    end

    def redirected_to : Request?
      @redirected_to
    end

    def resource_type : String
      jsinitializer["resourceType"].as_s
    end

    def response : Response?
      resp = send_message("response")
      return nil unless resp["response"]?

      connection.get_existing_object(resp["response"]["guid"].as_s).as(ResponseImpl).as?(Response)
    end

    def timing : RequestTiming
    end

    def url : String
      jsinitializer["url"].as_s
    end

    def final_request
      if rt = @redirected_to
        rt.final_request
      else
        self
      end
    end
  end
end
