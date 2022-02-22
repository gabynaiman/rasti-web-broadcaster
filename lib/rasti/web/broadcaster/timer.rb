module Rasti
  module Web
    class Broadcaster
      class Timer
        class << self

          def every(interval, &block)
            Thread.new do
              loop do
                execute_using_time_slot(interval, &block)
              end
            end
          end

          private

          def execute_using_time_slot(interval)
            started_at = Time.now

            Timeout.timeout(interval) do
              yield
            end

          rescue => ex
            Broadcaster.logger.error(self) { ex }

          ensure
            elapsed_time = Time.now - started_at
            sleep interval - elapsed_time if interval > elapsed_time
          end

        end
      end
    end
  end
end
