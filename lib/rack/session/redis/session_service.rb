require 'rack/session/abstract/id'
require 'rack/session/redis/redis_session_store'

module Rack
  module Session
    module Redis

      # SessionService provides simple cookie based session management.
      # Session data is stored in Redis (see RedisSessionStore for more information)
      # and the corresponding session key is maintained in the cookie.
      # You may treat SessionService as you would Rack::Session::Pool.
      #
      # Usage:
      #
      # use Rack::Session::Redis::SessionService, key: 'my_session_key',
      # domain: 'example.com'
      # path: '/',
      # expire_after: 3600,
      # redis_options: {host: 'redis-master.example.com', port: 6379, db: 13},
      # key_prefix: 'my:session:'
      #
      # You can use all options supported by Rack::Session::Abstract::ID.
      class SessionService < ::Rack::Session::Abstract::ID
        # default session expiration time
        DEFAULT_EXPIRATION_SEC = 60 * 60

        def initialize(app, options = {})
          super
          redis_options = options[:redis_options] || {}
          default_expiration = options[:expire_after] || DEFAULT_EXPIRATION_SEC
          key_prefix = options[:key_prefix] || ''
          redis_options = redis_options.merge({default_expiration: default_expiration, key_prefix: key_prefix})
          @store = Rack::Session::Redis::RedisSessionStore.new(redis_options)
        end

        # Override call in order to provide your own domain extraction logic
        def call(env)
          env['rack.session.options'][:domain] = get_domain_from_host(env)
          super env
        end

        def generate_sid
          loop do
            sid = super
            break sid unless @store.exists?(sid)
          end
        end

        #override
        def get_session(env, sid)
          unless sid && session = @store.load(sid)
            sid, session = generate_sid, {}
            unless @store.create(sid, session)
              raise "Session collision on '#{sid.inspect}'"
            end
          end
          [sid, session]
        end

        #override
        def set_session(env, sid, session, options)
          # sid key name which stores the session id inside a session object; backward compatibility with identity
          session[:_dawanda_sid] = sid unless session.empty?
          @store.store(sid, session, options)
          sid
        end

        #override
        def destroy_session(env, sid, options)
          @store.invalidate(sid)
          generate_sid unless options[:drop]
        end

        private

        # get root domain
        def get_domain_from_host(env)
          http_host = env['HTTP_HOST']
          return nil if http_host.nil? or http_host =~ /^localhost/
          split_host = http_host.split('.')
          if split_host.size > 2
            domain = ".#{split_host.drop(1).join('.')}"
          else
            domain = split_host.join('.')
          end
          domain
        end
      end
    end
  end
end
