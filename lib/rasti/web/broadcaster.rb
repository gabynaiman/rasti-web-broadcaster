require 'faye/websocket'
require 'broadcaster'
require 'class_config'
require_relative 'recurrent_executor'
require_relative 'broadcaster/safe_event_machine'
require_relative 'broadcaster/safe_rack_lint'
require_relative 'broadcaster/version'

module Rasti
  module Web
    class Broadcaster
      KEEP_ALIVE_EVENT = 'KeepAlive'

      extend ClassConfig

      attr_config :id,             'rasti.web.broadcaster'
      attr_config :redis_client,   Redic
      attr_config :redis_settings, 'redis://localhost:6379'
      attr_config :logger,         Logger.new(STDOUT)

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

      def initialize(app, headers={}, keep_alive_interval_seconds=nil, recurrent_executor=nil)
        @app = app
        @headers = headers
        @keep_alive_interval_seconds = keep_alive_interval_seconds || 15
        @recurrent_executor = recurrent_executor || RecurrentExecutor.new
        @event_sources = []
        @subscriptions_mutex = Mutex.new
        Thread.new { keep_alive_messages_loop }
      end

      def call(env)
        if Faye::EventSource.eventsource? env
          event_source = Faye::EventSource.new env, headers: @headers

          subscription_id = subscribe(event_source, channel_from(env))

          event_source.on :close do
            unsubscribe(event_source, subscription_id)
            event_source = nil
          end

          event_source.rack_response
        else
          app.call env
        end
      end

      private

      attr_reader :app, :event_sources, :subscriptions_mutex, :recurrent_executor

      def channel_from(env)
        env['PATH_INFO'][1..-1]
      end

      def subscribe(event_source, channel)
        subscription_id = self.class.subscribe channel do |message|
          event_source.send message[:data], event: message[:event], id: message[:id]
        end
        subscriptions_mutex.synchronize { event_sources << event_source }
        subscription_id
      end

      def unsubscribe(event_source, subscription_id)
        self.class.unsubscribe subscription_id
        subscriptions_mutex.synchronize { event_sources.delete(event_source) }
      end

      def keep_alive_messages_loop
        logger.info('Starting Keep alive messages loop')
        recurrent_executor.interval_loop(@keep_alive_interval_seconds) do
          logger.debug('Sending Keep Alive messages')
          begin
            subscriptions_mutex.synchronize do
              event_sources.each do |event_source|
                event_source.send({ current_time: Time.now.utc }.to_json, event: KEEP_ALIVE_EVENT)
              end
            end
          rescue => e
            logger.error('Error with keep alive messages: ', e)
          end
        end
      rescue => e
        logger.error('ERROR: keep_alive_messages_loop is no longer running!', e)
      end

      def logger
        self.class.logger
      end
    end
  end
end
