require "./channel_owner"
require "../page"

module Playwright
  private class BindingCall < ChannelOwner
    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      super(parent, type, guid, jsinitializer)
    end

    def name : String
      jsinitializer["name"].as_s
    end

    def call(binding : Page::Binding)
      frame = connection.get_existing_object(jsinitializer["frame"]["guid"].as_s).as(FrameImpl)
      source = SourceImpl.new(frame)
      args = Array(Any).new
      if handle = jsinitializer["handle"]?
        args << connection.get_existing_object(handle["guid"].as_s).as(JSHandleImpl)
      else
        jsinitializer["args"].as_a.each do |arg|
          args << Serialization.deserialize(SerializedValue.from_json(arg.to_json))
        end
      end
      result = binding.call(source, args)
      params = {"result" => Serialization.serialize_argument(result)}
      send_message("resolve", JSON.parse(params.to_json))
    rescue ex
      params = {"error" => JSON.parse(Serialization.serialize_error(ex).to_json)}
      send_message("reject", JSON.parse(params.to_json))
    end

    private class SourceImpl
      include Page::Binding::Source

      def initialize(@frame : Frame)
      end

      def context : BrowserContext?
        page.try &.context
      end

      def page : Page?
        frame.page
      end

      def frame : Frame
        @frame
      end
    end
  end
end
