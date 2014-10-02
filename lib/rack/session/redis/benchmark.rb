require 'securerandom'

require_relative 'session_service'

service = Rack::Session::Redis::SessionService.new(nil,
                                                   :redis_options => {:host => 'localhost', :port => 6379},
                                                   :statsd_host => '192.168.59.103:8125')


def generate_session
  {
      :user_id => rand,
      :data => SecureRandom.base64
  }
end

# class Rack::Session::Redis::SessionService
#   def set_session(env, sid, session, options)
#     with_stats do
#       raise Redis::TimeoutError
#     end
#   end
# end

c = 0

100000.times do
  session_id = SecureRandom.hex
  begin
    if c % 100 == 0
      sleep 0.1
    end
    service.set_session(nil, session_id, generate_session, {})
  rescue => e
    puts c += 1
  end
  service.get_session(nil, session_id)
  service.destroy_session(nil, session_id, {})
end

