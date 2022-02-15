require_relative 'minitest_helper'

describe Rasti::Web::Broadcaster do

  def event_headers
    event = []
    event << 'HTTP/1.1 200 OK'
    event << 'Content-Type: text/event-stream'
    event << 'Cache-Control: no-cache, no-store'
    event << 'Connection: close'
    event << 'Access-Control-Allow-Origin: *'
    event << ''
    event << 'retry: 5000'
    event << ''
    event << ''
    event.join("\r\n")
  end

  def event_for(options)
    event = []
    event << "event: #{options[:event]}" if options[:event]
    event << "id: #{options[:id]}" if options[:id]
    event << "data: #{options[:data]}"
    event << ''
    event << ''
    event.join("\r\n")
  end

  def wait_for(&block)
    Timeout.timeout(3) do
      while !block.call
        sleep 0.001
      end
    end
  end

  let(:headers) { {'Access-Control-Allow-Origin' => '*'} }

  let(:inner_app) { ->(env) { [200, {}, ['hello']] } }

  before do
    @sut = Rasti::Web::Broadcaster.new inner_app, headers, keep_alive_interval_seconds=0.1
  end

  it 'Handle events' do
    env = Rack::MockRequest.env_for'/channel_1', 'HTTP_ACCEPT' => 'text/event-stream', 'HTTP_HOST' => 'localhost'
    sse_receiver = SseReceiver.new(env)

    Rasti::Web::Broadcaster.publish 'channel_1', data: 'message 0'
    sleep(0.01)

    @sut.call env

    Rasti::Web::Broadcaster.publish 'channel_1', data: 'message 1', event: 'event_1', id: 1
    Rasti::Web::Broadcaster.publish 'channel_2', data: 'message 2'
    Rasti::Web::Broadcaster.publish 'channel_1', data: 'message 3'

    wait_for { sse_receiver.regular_events.count == 3 }
    wait_for { sse_receiver.keep_alive_events.count > 0 }

    sse_receiver.close_connection

    sse_receiver.regular_events.must_equal [
      event_headers,
      event_for(data: 'message 1', event: 'event_1', id: 1),
      event_for(data: 'message 3')
    ]
  end

  describe 'Keep Alive messages loop' do
    it 'sends keep alive messages every {keep_alive_interval_seconds} when an event_source subscribes' do
      env = env_for('channel_1')
      sse_receiver = SseReceiver.new(env)

      @sut.call env

      wait_for { sse_receiver.keep_alive_events.count == 5 }
      sse_receiver.close_connection
    end

    it 'Sends keep alive messages to all subscribers and stops when connection is closed' do
      manual_executor = ManualExecutor.new
      sut = Rasti::Web::Broadcaster.new(inner_app, headers, nil, manual_executor)
      sleep(0.01) # giving time to keep_alive_messages_loop to run

      env_1, env_2 = [env_for('channel_1'), env_for('channel_2')]

      sse_receiver_1 = SseReceiver.new(env_1)
      sse_receiver_2 = SseReceiver.new(env_2)

      manual_executor.keep_alive_callback # There are no subscribers yet, so nothing happens
      sse_receiver_1.keep_alive_events.size.must_equal 0
      sse_receiver_2.keep_alive_events.size.must_equal 0

      [env_1, env_2].each { |env| sut.call env }

      manual_executor.keep_alive_callback
      sse_receiver_1.keep_alive_events.size.must_equal 1
      sse_receiver_2.keep_alive_events.size.must_equal 1

      # After close, there are no more keep alive messages
      [sse_receiver_1, sse_receiver_2].each { |receiver| receiver.close_connection }
      sleep(0.01)

      manual_executor.keep_alive_callback # There shouldn't be new events
      sse_receiver_1.keep_alive_events.size.must_equal 1
      sse_receiver_2.keep_alive_events.size.must_equal 1
    end
  end

  it 'Ignore normal request' do
    env = Rack::MockRequest.env_for '/resource/123'

    status, headers, body = @sut.call env

    status.must_equal 200
    headers.must_be_empty
    body.must_equal ['hello']
  end

  def env_for(channel)
    Rack::MockRequest.env_for "/#{channel}", 'HTTP_ACCEPT' => 'text/event-stream', 'HTTP_HOST' => 'localhost'
  end
end
