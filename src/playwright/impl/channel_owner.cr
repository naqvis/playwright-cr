require "json"
require "./waitable"

module Playwright
  private class ChannelOwner
    include JSON::Serializable

    @[JSON::Field(ignore: true)]
    getter connection : Connection
    @[JSON::Field(ignore: true)]
    @parent : ChannelOwner?
    @[JSON::Field(ignore: true)]
    getter objects : Hash(String, ChannelOwner)
    @[JSON::Field(ignore: true)]
    getter type : String
    getter guid : String
    @[JSON::Field(ignore: true)]
    getter jsinitializer : JSON::Any

    def initialize(connection : Connection, type : String, guid : String)
      initialize(connection, nil, type, guid, JSON::Any.new("{}"))
    end

    def initialize(parent : ChannelOwner, type : String, guid : String, jsinitializer : JSON::Any)
      initialize(parent.connection, parent, type, guid, jsinitializer)
    end

    def initialize(@connection, @parent, @type, @guid, @jsinitializer)
      @objects = Hash(String, ChannelOwner).new
    end

    def register
      @connection.register_object(guid, self)
      if p = @parent
        p.objects[@guid] = self
      end
    end

    def disconnect
      if p = @parent
        p.objects.delete(guid)
      end
      connection.unregister_object(guid)
      @objects.each do |_, v|
        v.disconnect
      end
      @objects.clear
    end

    def send_message_async(method : String, params : JSON::Any)
      connection.send_message_async(guid, method, params)
    end

    def send_message(method : String)
      send_message(method, JSON::Any.new(Hash(String, JSON::Any).new))
    end

    def send_message(method : String, params : JSON::Any)
      connection.send_message(guid, method, params)
    end

    def send_message_no_wait(method : String)
      send_message_no_wait(method, JSON::Any.new(Hash(String, JSON::Any).new))
    end

    def send_message_no_wait(method : String, params : JSON::Any)
      connection.send_message_async(guid, method, params)
    end

    def to_deferred(waitable : Waitable(T)) forall T
      DeferredImpl(T).new(waitable, connection)
    end

    def handle_event(_event : String, _params : JSON::Any)
    end

    protected def function_body?(script)
      expr = script.strip
      expr.starts_with?("function") || expr.starts_with?("async ") || expr.includes?("=>")
    end

    private struct DeferredImpl(T) < Deferred(T)
      @waitable : Waitable(T)

      def initialize(waitable, @connection : Connection)
        @waitable = waitable
      end

      def get : T
        while (!@waitable.done?)
          @connection.process_one_message
        end
        @waitable.get
      end
    end
  end
end
