require "json"
require "log"
require "./transport"
require "./channel_owner"
require "./protocol"

module Playwright
  ::Log.setup(:error)
  Log = ::Log.for(self)

  private class Connection
    @transport : Transport
    getter objects : Hash(String, ChannelOwner)
    getter callbacks : Hash(Int32, WaitableResult(JSON::Any))
    @last_id : Int32 = 0
    getter(root : Root) { Root.new(self) }

    def initialize(input : IO, output : IO)
      @transport = Transport.new(input, output)
      @objects = Hash(String, ChannelOwner).new
      @callbacks = Hash(Int32, WaitableResult(JSON::Any)).new
    end

    def start
      @transport.start
    end

    def close
      @transport.close
    end

    def send_message(guid : String, method : String, params : JSON::Any)
      Log.debug { "Sending message : guid: #{guid} , method: #{method}, params: #{params}" }
      root.to_deferred(send_message_async(guid, method, params)).get
    end

    def send_message_async(guid : String, method : String, params : JSON::Any) : Waitable(JSON::Any)
      @last_id += 1
      result = WaitableResult(JSON::Any).new
      callbacks[@last_id] = result

      message = {} of String => JSON::Any
      message["id"] = JSON::Any.new(@last_id.to_i64)
      message["guid"] = JSON::Any.new(guid)
      message["method"] = JSON::Any.new(method)
      message["params"] = params

      @transport.send(message.to_json)
      result.as(Waitable(JSON::Any))
    end

    def wait_for_object_with_known_name(guid : String)
      loop do
        return objects[guid] if objects.has_key?(guid)
        process_one_message
      end
    end

    def get_existing_object(guid : String)
      res = objects[guid]?
      raise PlaywrightException.new("Object doesn't exist: #{guid}") if res.nil?
      res.not_nil!
    end

    def register_object(guid : String, obj : ChannelOwner)
      objects[guid] = obj
    end

    def unregister_object(guid : String)
      objects.delete(guid)
    end

    def process_one_message
      msg = @transport.poll(1000.milliseconds)
      return if msg.nil?
      Log.debug { "Message Received: #{msg}" }
      message = Message.from_json(msg)
      dispatch(message)
    end

    private def dispatch(message : Message)
      if message.id != 0
        cb = callbacks[message.id]?
        raise PlaywrightException.new("Cannot find command to response: #{message.id}") if cb.nil?
        callbacks.delete(message.id)
        if message.error.nil?
          cb.complete(message.result || JSON::Any.new(""))
        else
          if message.error.not_nil!.error
            cb.complete_exceptionally(ServerException.new(message.error.not_nil!.error.not_nil!))
          end
          raise PlaywrightException.new(message.error.to_s)
        end
        return
      end

      if message.method == "__create__"
        create_remote_object(message.guid, message.params)
        return
      end
      if message.method == "__dispose__"
        obj = objects[message.guid]?
        raise PlaywrightException.new("Cannot find object to dispose: #{message.guid}") if obj.nil?
        obj.disconnect
        return
      end

      obj = objects[message.guid]?
      raise PlaywrightException.new("Cannot find object to call #{message.method}: #{message.guid}") if obj.nil?
      obj.handle_event(message.method, message.params)
    end

    def create_remote_object(parent_guid : String, params : JSON::Any)
      type = params["type"].as_s
      guid = params["guid"].as_s
      root.register
      parent = objects[parent_guid]?
      raise PlaywrightException.new("Cannot find parent object #{parent_guid} to create #{guid}") if parent.nil?
      jsinitializer = params["initializer"]

      obj = case type
            when "Android"
              # Not implemented
              # Android.new(parent,type,guid,jsinitializer)
            when "AndroidSocket"
              # Not implemented
              # AndroidSocket.new(parent,type,guid,jsinitializer)
            when "Electron"
              # Not implemented
              # ElectronImpl.new(parent,type,guid,jsinitializer)
            when "BindingCall"
              BindingCall.new(parent, type, guid, jsinitializer)
            when "BrowserType"
              BrowserTypeImpl.new(parent, type, guid, jsinitializer)
            when "Browser"
              BrowserImpl.new(parent, type, guid, jsinitializer)
            when "BrowserContext"
              BrowserContextImpl.new(parent, type, guid, jsinitializer)
            when "ConsoleMessage"
              ConsoleMessageImpl.new(parent, type, guid, jsinitializer)
            when "Dialog"
              DialogImpl.new(parent, type, guid, jsinitializer)
            when "Download"
              DownloadImpl.new(parent, type, guid, jsinitializer)
            when "ElementHandle"
              ElementHandleImpl.new(parent, type, guid, jsinitializer)
            when "Frame"
              FrameImpl.new(parent, type, guid, jsinitializer)
            when "JSHandle"
              JSHandleImpl.new(parent, type, guid, jsinitializer)
            when "Page"
              PageImpl.new(parent, type, guid, jsinitializer)
            when "Playwright"
              PlaywrightImpl.new(parent, type, guid, jsinitializer)
            when "Request"
              RequestImpl.new(parent, type, guid, jsinitializer)
            when "Response"
              ResponseImpl.new(parent, type, guid, jsinitializer)
            when "Route"
              RouteImpl.new(parent, type, guid, jsinitializer)
            when "Stream"
              Stream.new(parent, type, guid, jsinitializer)
            when "Selectors"
              SelectorsImpl.new(parent, type, guid, jsinitializer)
            when "WebSocket"
              WebSocketImpl.new(parent, type, guid, jsinitializer)
            when "Worker"
              WorkerImpl.new(parent, type, guid, jsinitializer)
            else
              raise PlaywrightException.new("Uknown type : #{type}")
            end
      obj.register unless obj.nil?
      obj
    end

    private class Root < ChannelOwner
      def initialize(connection : Connection)
        super(connection: connection, type: "", guid: "")
      end
    end

    private struct Message
      include JSON::Serializable
      getter id : Int32 = 0
      getter guid : String = ""
      getter method : String = ""
      getter params : JSON::Any = JSON::Any.new(Hash(String, JSON::Any).new)
      getter result : JSON::Any?
      getter error : SerializedError?
    end
  end
end
