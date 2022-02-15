require_relative 'coverage_helper'
require 'minitest/autorun'
require 'minitest/colorin'
require 'pry-nav'
require 'rasti-web-broadcaster'
require 'rack/test'

Rasti::Web::Broadcaster.logger.level = Logger::ERROR


class ManualExecutor
  def interval_loop(_interval_seconds, &block)
    @given_callback = block
    while true
      sleep(0.01)
    end
  end

  def keep_alive_callback
    @given_callback.call
  end
end

class SseReceiver
  attr_reader :keep_alive_events, :regular_events

  def initialize(env)
    @keep_alive_events = []
    @regular_events = []
    env['async.callback'] = proc do |(_status, _headers, body)|
      @event_source = body.instance_variable_get(:@socket_object)
      body.each do |e|
        if e.include?("event: #{Rasti::Web::Broadcaster::KEEP_ALIVE_EVENT}")
          @keep_alive_events << e
        else
          @regular_events << e
        end
      end
    end
  end

  def close_connection
    @event_source.close
  end
end