require 'minitest_helper'

describe Rasti::Web::Broadcaster do

  def event_headers
    event = []
    event << 'HTTP/1.1 200 OK'
    event << 'Content-Type: text/event-stream'
    event << 'Cache-Control: no-cache, no-store'
    event << 'Connection: close'
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

  let(:app) { Rasti::Web::Broadcaster.new ->(env) { [200, {}, ['hello']] } }

  it 'Handle events' do
    env = Rack::MockRequest.env_for '/channel_1', 'HTTP_ACCEPT' => 'text/event-stream',
                                                  'HTTP_HOST'   => 'localhost'

    event_source = nil
    events = []
    
    env['async.callback'] = proc do |(status, headers, body)|
      event_source = body.instance_variable_get(:@socket_object)
      body.each { |e| events << e }
    end
    
    Rasti::Web::Broadcaster.publish 'channel_1', data: 'message 0'

    app.call env

    Rasti::Web::Broadcaster.publish 'channel_1', data: 'message 1', event: 'event_1', id: 1
    Rasti::Web::Broadcaster.publish 'channel_2', data: 'message 2'
    Rasti::Web::Broadcaster.publish 'channel_1', data: 'message 3'

    wait_for { events.count == 3 }

    event_source.close

    events.must_equal [
      event_headers,
      event_for(data: 'message 1', event: 'event_1', id: 1), 
      event_for(data: 'message 3')
    ]
  end

  it 'Ignore normal request' do
    env = Rack::MockRequest.env_for '/resource/123'

    status, headers, body = app.call env

    status.must_equal 200
    headers.must_be_empty
    body.must_equal ['hello']
  end

end