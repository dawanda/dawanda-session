require 'redis'

module Rack
  module Session
    module Redis
      class RedisSessionStore
        # Simple implementation of session store. Use Marshal for serialization.
        # TODO: allow different serialization strategies: Marshall/JSON/etc.
        # Options must contain :default_expiration key otherwise exception will be thrown
        # @param [Hash] options
        def initialize(options)
          raise ArgumentError, 'No :default_expiration value provided' unless options[:default_expiration]
          @default_expiration = options[:default_expiration]
          @key_prefix         = options[:key_prefix] || ''
          @redis              = options[:redis] || ::Redis.new(options)
        end

        # Determine if a key exists.
        #
        # @param [String] key
        # @return [Boolean]
        def exists?(key)
          with_fallback(false) do
            @redis.exists(prefix(key))
          end
        end

        # Get the value of a key. Updates expiration time.
        #
        # @param [String] key
        # @return [String]
        def load(key)
          with_fallback({ dummy: true }) do
            redis_key = prefix(key)
            value = @redis.get(redis_key)
            Marshal.load(value) if value
          end
        end

        # Sets key to hold a given value and set key TTL.
        # If :expire_after options is less or equal 0 TTL is not set on key.
        # @param [String] key
        # @param [String] value
        # @param [Hash] options
        # @return [String] provided value
        def store(key, value, options = {})
          with_fallback(nil) do
            expiration = options[:expire_after] || @default_expiration
            value = Marshal.dump(value)
            redis_key = prefix(key)
            if expiration > 0
              @redis.setex(redis_key, expiration, value)
            else
              @redis.set(redis_key, value)
            end
            value
          end
        end

        # Set the value of a key, only if the key does not exist.
        #
        # @param [String] key
        # @param [String] value
        # @return [Boolean] whether the key was set or not
        def create(key, value)
          with_fallback(nil) do
            redis_key = prefix(key)
            value = Marshal.dump(value)
            @redis.setnx(redis_key, value)
          end
        end

        # Delete session key.
        #
        # @param [String] key
        # @return [String] deleted value or nil if key doesn't exist
        def invalidate(key)
          with_fallback(nil) do
            redis_key = prefix(key)
            if value = @redis.get(redis_key)
              @redis.del(redis_key)
              Marshal.load(value)
            end
          end
        end

        private def with_fallback(fallback_return)
          yield
        rescue ::Redis::BaseError => e
          Bugsnag.notify(e) if Object.const_defined?('Bugsnag')
          fallback_return
        end

        private def prefix(key)
          unless key.start_with?(@key_prefix)
            @key_prefix + key
          else
            key
          end
        end
      end
    end
  end
end
