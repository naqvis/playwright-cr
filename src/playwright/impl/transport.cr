require "time"

module Playwright
  private class Transport
    Log.for(Transport)

    def initialize(input : IO, output : IO)
      @closed = false
      @incoming = ::Channel(String).new # (2)
      @outgoing = ::Channel(String).new(2)
      @reader = Reader.new(input, @incoming)
      @writer = Writer.new(output, @outgoing)
    end

    def start
      spawn { @reader.run }
      spawn { @writer.run }
    end

    def send(message : String)
      raise PlaywrightException.new("Playwright connection closed") if @closed
      Log.info { "Sending message via transport: #{message}" }
      @outgoing.send(message)
    end

    def poll(duration : Time::Span) : String?
      raise PlaywrightException.new("Playwright connection closed") if @closed
      select
      when msg = @incoming.receive
        msg
      when timeout(duration)
      # raise "Timedout"
      end
    end

    def close
      return if @closed
      @closed = true
      @writer.close
      @reader.close
    end

    private struct Reader
      def initialize(@io : IO, @chan : ::Channel(String))
        @stop = false
      end

      def close
        @stop = true
      end

      def run
        len_buf = Bytes.new(4)
        loop do
          break if @stop || @io.closed?
          size = @io.read(len_buf)
          next unless size == len_buf.size
          msg_len = IO::ByteFormat::LittleEndian.decode(UInt32, len_buf)
          next if msg_len == 0
          msg_buf = Bytes.new(msg_len)
          size = 0
          while size < msg_len
            size += @io.read(msg_buf[size..])
          end
          next unless size == msg_len
          @chan.send(String.new(msg_buf))
        end
      end
    end

    private struct Writer
      def initialize(@io : IO, @chan : ::Channel(String))
        @stop = false
      end

      def close
        @stop = true
      end

      def run
        loop do
          break if @stop || @io.closed?
          select
          when msg = @chan.receive
          #
          when timeout(100.milliseconds)
            next
          end
          len = msg.bytesize
          next if len == 0
          @io.write_bytes(len, IO::ByteFormat::LittleEndian)
          @io.write(msg.to_slice)
        end
      end
    end
  end
end
