require 'rack/session/redis/session_service'
require 'rack/session/redis/redis_session_store'
require 'rack'

describe Rack::Session::Redis::SessionService do

  let(:sid) do
    session_service.generate_sid
  end

  let(:fake_session) do
    {:user_id => 'mallory'}
  end

  let(:redis_options) do
    {:host => 'example.com', :port => 666, :db => 1}
  end

  let(:default_options) do
    {:key => '_session_key', :path => '/', :expire_after => 10, :redis_options => redis_options, :key_prefix => 'hello:prefix:'}
  end

  let(:session_store) do
    double(:RedisSessionStore)
  end

  let(:session_service) do
    Rack::Session::Redis::SessionService.new({})
  end

  before do
    allow(Rack::Session::Redis::RedisSessionStore).to receive(:new).and_return(session_store)
    allow(session_store).to receive(:create).and_return(true)
    allow(session_store).to receive(:load).and_return(fake_session)
    allow(session_store).to receive(:exists?).and_return(false)
    allow(session_store).to receive(:invalidate).and_return(fake_session)
  end

  it 'should take the session from the Authorization header if not found in the cookie' do
    session_service = Rack::Session::Redis::SessionService.new(nil, { key: 'foobar', cookie_only: false })
    expect(
      session_service.extract_session_id({
        'HTTP_AUTHORIZATION' => 'foobar 8s7dg98dsa7ft087',
        'QUERY_STRING'       => '',
        'REQUEST_METHOD'     => 'GET',
        'rack.input'         => []
      })
    ).to eq('8s7dg98dsa7ft087')
  end

  it 'should check if the generated sid is not present in the underlying store' do
    expect(session_store).to receive(:exists?).and_return(false)
    session_service.generate_sid
  end

  it 'should create new empty session and new session id if session_id does not exist' do
    allow(session_store).to receive(:load).and_return(nil)
    id, session = session_service.get_session(nil, sid)
    expect(id).not_to eq(sid)
    expect(session).to eq({})
  end

  it 'should return existing session for a given id' do
    expect(session_store).to receive(:load).with(sid).and_return(fake_session)
    id, session = session_service.get_session(nil, sid)
    expect(id).to eq(sid)
    expect(session).to eq(fake_session)
  end

  it 'should support rack compliant options in a constructor and interpret them correctly' do
    expect(Rack::Session::Redis::RedisSessionStore).to receive(:new).with(redis_options.merge(:default_expiration => 10, :key_prefix => 'hello:prefix:'))
    Rack::Session::Redis::SessionService.new(nil, default_options)
  end

  it 'should create a statsd client on initialization' do
    expect(Statsd::Client).to receive(:new).with('localhost', 8125)
    Rack::Session::Redis::SessionService.new(nil, default_options)
  end

  it 'should throw exception on session collision' do
    allow(session_store).to receive(:create).and_return(false)
    allow(session_store).to receive(:load).and_return(nil)
    expect { session_service.get_session(nil, sid) }.to raise_error RuntimeError
  end

  it 'should destroy session and return new session id' do
    expect(session_store).to receive(:invalidate).with(sid)
    new_sid = session_service.destroy_session(nil, sid, {})
    expect(new_sid).to_not eq(sid)
  end

end
