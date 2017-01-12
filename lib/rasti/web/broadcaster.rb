require 'faye/websocket'
require 'broadcaster'
require 'class_config'

require_relative 'broadcaster/version'

module Rasti
  module Web
    class Broadcaster

      extend ClassConfig

      attr_config :id,        'rasti.web.broadcaster'
      attr_config :redis_url, 'redis://localhost:6379'
      attr_config :logger,    Logger.new(STDOUT)

      class << self

        extend Forwardable

        def_delegators :broadcaster, :subscribe, 
                                     :unsubscribe, 
                                     :publish

        private

        def broadcaster
          @broadcaster ||= ::Broadcaster.new configuration
        end

      end

      def initialize(app)
        @app = app
      end

      def call(env)
        if Faye::EventSource.eventsource? env
          event_source = Faye::EventSource.new env
          channel = env['PATH_INFO'][1..-1]

          subscription_id = self.class.subscribe channel do |message|
            event_source.send message[:data], event: message[:event], 
                                              id:    message[:id]
          end

          event_source.on :close do
            self.class.unsubscribe subscription_id
            event_source = nil
          end

          event_source.rack_response
        else
          app.call env
        end
      end

      private

      attr_reader :app

    end
  end
end