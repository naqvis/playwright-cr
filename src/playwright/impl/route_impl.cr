require "mime"
require "./channel_owner"
require "../route"

module Playwright
  private class RouteImpl < ChannelOwner
    include Route

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
    end

    def abort(error_code : String?) : Nil
      if err = error_code
        send_message("abort", JSON.parse({"errorCode" => err}.to_json))
      else
        send_message("abort")
      end
    end

    def continue(overrides : ContinueOverrides?) : Nil
      overrides ||= ContinueOverrides.new
      params = JSON.parse(overrides.to_json)
      if params["headers"]?
        params.as_h["headers"] = Serialization.to_protocol(overrides.headers.not_nil!)
      end
      send_message("continue", params)
    end

    def fulfill(response : FulfillResponse) : Nil
      status = response.status == 0 ? 200 : (response.status.nil? ? 200 : response.status.not_nil!)
      body = ""
      is_base64 = false
      length = 0
      if (path = response.path)
        buffer = File.read(path)
        body = Base64.strict_encode(buffer)
        is_base64 = true
        length = buffer.bytesize
      elsif (rbody = response.body)
        body = rbody
        length = body.bytesize
      elsif (bytes = response.body_bytes)
        body = Base64.strict_encode(bytes)
        is_base64 = true
        length = bytes.size
      end

      headers = {} of String => String
      if (hdr = response.headers)
        hdr.each { |k, v| headers[k.downcase] = v }
      end
      if (ct = response.content_type)
        headers["content-type"] = ct
      elsif path = response.path
        headers["content-type"] = MIME.from_extension(path.extension, "application/octet-stream")
      end

      headers["content-length"] = length.to_s unless length == 0 || headers.has_key?("content-length")
      params = {} of String => JSON::Any
      params["status"] = JSON::Any.new(status.to_i64)
      params["headers"] = Serialization.to_protocol(headers)
      params["isBase64"] = JSON::Any.new(is_base64)
      params["body"] = JSON::Any.new(body)

      send_message("fulfill", JSON::Any.new(params))
    end

    def request : Request
      connection.get_existing_object(jsinitializer["request"]["guid"].as_s).as(RequestImpl)
    end
  end
end
