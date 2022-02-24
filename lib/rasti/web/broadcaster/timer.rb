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
            yield

          rescue => ex
            Broadcaster.logger.error(self) { ex }

          ensure
            elapsed_time = Time.now - started_at
            if elapsed_time > interval
              Broadcaster.logger.warn(self) { "Elapsed time #{elapsed_time}s for interval of #{interval}s" }
            else
              sleep interval - elapsed_time
            end
          end

        end
      end
    end
  end
end
