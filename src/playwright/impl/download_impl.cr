require "./channel_owner"
require "./stream"
require "../download"

module Playwright
  private class DownloadImpl < ChannelOwner
    include Download

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
    end

    def create_read_stream : IO?
      result = send_message("stream")
      return nil unless result["stream"]?
      connection.get_existing_object(result["stream"]["guid"].as_s).as(Stream).stream
    end

    def delete : Nil
      send_message("delete")
    end

    def failure : String?
      res = send_message("failure")
      res["error"].as_s?
    end

    def path : Path?
      res = send_message("path")
      res["value"]? ? Path[res["value"].as_s] : nil
    end

    def save_as(path : String) : Nil
      send_message("saveAs", JSON::Any.new({"path" => JSON::Any.new(path)}))
    end

    def save_as(path : Path) : Nil
      save_as(path.to_s)
    end

    def suggested_filename : String
      jsinitializer["suggestedFilename"].as_s
    end

    def url : String
      jsinitializer["url"].as_s
    end
  end
end
