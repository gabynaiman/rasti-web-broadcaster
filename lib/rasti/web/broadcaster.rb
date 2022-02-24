require 'faye/websocket'
require 'broadcaster'
require 'class_config'

require_relative 'broadcaster/safe_event_machine'
require_relative 'broadcaster/safe_rack_lint'
require_relative 'broadcaster/timer'
require_relative 'broadcaster/version'

module Rasti
  module Web
    class Broadcaster

      KEEP_ALIVE_EVENT = 'keepAlive'

      extend ClassConfig

      attr_config :id,                  'rasti.web.broadcaster'
      attr_config :redis_client,        Redic
      attr_config :redis_settings,      'redis://localhost:6379'
      attr_config :logger,              Logger.new(STDOUT)
      attr_config :keep_alive_interval

      @mutex = Mutex.new

      class << self

        extend Forwardable

        def_delegators :broadcaster, :subscribe,
                                     :unsubscribe,
                                     :publish

        private

        def broadcaster
          @mutex.synchronize do
            @broadcaster ||= ::Broadcaster.new configuration
          end
        end

      end

      def initialize(app, headers={})
        @app = app
        @headers = headers
        @mutex = Mutex.new
        @subscriptions = {}

        start_sending_keep_alive_messages
      end

      def call(env)
        if Faye::EventSource.eventsource? env
          event_source = Faye::EventSource.new env, headers: headers

          subscription_id = subscribe channel_from(env), event_source

          event_source.on :close do
            unsubscribe subscription_id
            event_source = nil
          end

          event_source.rack_response
        else
          app.call env
        end
      end

      private

      attr_reader :app, :headers, :mutex, :subscriptions

      def subscribe(channel, event_source)
        subscription_id = self.class.subscribe channel do |message|
          send_message(event_source, **message)
        end

        mutex.synchronize { subscriptions[subscription_id] = event_source }

        subscription_id
      end

      def unsubscribe(subscription_id)
        self.class.unsubscribe subscription_id
        mutex.synchronize { subscriptions.delete subscription_id }
      end

      def send_message(event_source, data:, event: nil, id: nil)
        event_source.send data, event: event, id: id
      end

      def start_sending_keep_alive_messages
        if self.class.keep_alive_interval
          Timer.every self.class.keep_alive_interval do
            subscriptions.each do |subscription_id, event_source|
              self.class.logger.debug(self.class) { "Sending keep alive to #{subscription_id}" }
              send_message event_source, data: '', event: KEEP_ALIVE_EVENT
            end
          end
        end
      end

      def channel_from(env)
        env['PATH_INFO'][1..-1]
      end

    end
  end
end
