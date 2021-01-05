require "./spec_helper"

module Playwright
  def self.wait_for_condition(condition : Array(Bool))
    condition.size.should eq(1)
    start = Time.monotonic
    while !condition[0]
      page.wait_for_timeout(100).get
      fail "Timed out" unless (Time.monotonic - start).seconds < 30
    end
  end

  it "should work" do
    page.evaluate(%(port => {
      let cb;
      const result = new Promise(f => cb = f);
      const ws = new WebSocket('ws://localhost:' + port + '/ws');
      ws.addEventListener('message', data => { ws.close(); cb(data.data);});
      return result;
    }), server.port.to_s).should eq("incoming")
  end

  it "should emit close events" do
    socket_closed = [false]
    log = [] of String
    websockets = [] of WebSocket
    page.add_listener(Page::EventType::WEBSOCKET, ListenerImpl(Page::EventType).new { |evt|
      ws = evt.data.as(WebSocket)
      log << "open<#{ws.url}>"
      websockets << ws
      ws.add_listener(WebSocket::EventType::CLOSE, ListenerImpl(WebSocket::EventType).new { |_|
        log << "close"
        socket_closed[0] = true
      })
    })

    page.evaluate(%(port => {
      const ws = new WebSocket('ws://localhost:' + port + '/ws');
      ws.addEventListener('open', () => ws.close());
    }), server.port.to_s)
    wait_for_condition(socket_closed)
    websockets.size.should be > 0
    log.should eq(["open<ws://localhost:#{server.port}/ws>", "close"])
    websockets[0].is_closed.should be_true
  end

  it "should emit frame events" do
    socket_closed = [false]
    log = [] of String
    page.add_listener(Page::EventType::WEBSOCKET, ListenerImpl(Page::EventType).new { |evt|
      ws = evt.data.as(WebSocket)
      log << "open"

      ws.add_listener(WebSocket::EventType::FRAMESENT, ListenerImpl(WebSocket::EventType).new { |e|
        log << "sent<#{e.data.as(WebSocket::FrameData).text}>"
      })
      ws.add_listener(WebSocket::EventType::FRAMERECEIVED, ListenerImpl(WebSocket::EventType).new { |e|
        log << "received<#{e.data.as(WebSocket::FrameData).text}>"
      })
      ws.add_listener(WebSocket::EventType::CLOSE, ListenerImpl(WebSocket::EventType).new { |_|
        log << "close"
        socket_closed[0] = true
      })
    })
    page.evaluate(%(port => {
      const ws = new WebSocket('ws://localhost:' + port + '/ws');
      ws.addEventListener('open', () => ws.send('outgoing'));
      ws.addEventListener('message', () => { ws.close(); });
    }), server.port.to_s)
    wait_for_condition(socket_closed)
    if webkit?
      # there is intermittent <receivedA+g=> message in WebKit.
      log.delete("received<A+g=>")
    end
    log.size.should be >= 3
    log[0].should eq("open")
    log[3].should eq("close")
    log.sort!
    log.should eq(["close", "open", "received<incoming>", "sent<outgoing>"])
  end

  it "should emit binary frame events" do
    socket_closed = [false]
    sent = [] of WebSocket::FrameData
    page.add_listener(Page::EventType::WEBSOCKET, ListenerImpl(Page::EventType).new { |evt|
      ws = evt.data.as(WebSocket)
      ws.add_listener(WebSocket::EventType::FRAMESENT, ListenerImpl(WebSocket::EventType).new { |e|
        sent << e.data.as(WebSocket::FrameData)
      })
      ws.add_listener(WebSocket::EventType::CLOSE, ListenerImpl(WebSocket::EventType).new { |_|
        socket_closed[0] = true
      })
    })
    page.evaluate(%(port => {
      const ws = new WebSocket('ws://localhost:' + port + '/ws');
      ws.addEventListener('open', () => {
        const binary = new Uint8Array(5);
        for (let i = 0; i < 5; ++i)
          binary[i] = i;
        ws.send('text');
        ws.send(binary);
        ws.close();
      });
    }), server.port.to_s)
    wait_for_condition(socket_closed)
    sent[0].text.should eq("text")
    0.upto(4) do |i|
      (sent[1].body[i]).should eq(i)
    end
  end

  it "should reject wait for event on socket close" do
    ws_event = page.wait_for_event(Page::EventType::WEBSOCKET)
    page.evaluate(%(port => {
      window.ws = new WebSocket('ws://localhost:' + port + '/ws');
    }), server.port.to_s)
    ws = ws_event.get.data.as(WebSocket) || fail "unable to get ws handle"
    ws.wait_for_event(WebSocket::EventType::FRAMERECEIVED).get
    frame_sent_event = ws.wait_for_event(WebSocket::EventType::FRAMESENT)
    page.evaluate("window.ws.close()")
    expect_raises(PlaywrightException, "Socket closed") do
      frame_sent_event.get
    end
  end

  it "should reject wait for event on page close" do
    ws_event = page.wait_for_event(Page::EventType::WEBSOCKET)
    page.evaluate(%(port => {
      window.ws = new WebSocket('ws://localhost:' + port + '/ws');
    }), server.port.to_s)
    ws = ws_event.get.data.as(WebSocket) || fail "unable to get ws handle"
    ws.wait_for_event(WebSocket::EventType::FRAMERECEIVED).get
    frame_sent_event = ws.wait_for_event(WebSocket::EventType::FRAMESENT)
    page.close
    expect_raises(PlaywrightException, "Page closed") do
      frame_sent_event.get
    end
  end
end
