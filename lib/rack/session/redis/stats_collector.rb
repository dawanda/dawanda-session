require 'redis'
require 'statsd/client'

module Rack
  module Session
    module Redis
      # Using 'dawanda-statsd-client' in order to collect number of timeouts when invoking a given block of code, see StatsCollector#with_stats
      module StatsCollector
        REQUEST_DURATION = 'sessions.request_duration'
        TIMEOUT_COUNTER = 'sessions.timeout'

        # Sends duration of a given block invocation to statsd. Increment 'session.timeout' counter on exception.
        def with_stats
          return unless block_given?
          yield
        rescue ::Redis::TimeoutError => e
          # collects stats
          statsd_client.increment(TIMEOUT_COUNTER)
          raise e
        end

        # Configures statsd client if non-nil argument given or returns the client instance otherwise.
        def statsd_client(host_port = nil)
          unless host_port.nil?
            host, port = host_port.split(':')
            @client ||= Statsd::Client.new(host, port.to_i)
          end
          @client
        end
      end
    end
  end
end
