require 'redis'
require 'securerandom'
require 'rack/session/redis/redis_session_store'

describe Rack::Session::Redis::RedisSessionStore do
  PREFIX = 'hello:prefix:'

  let(:key) {
    SecureRandom.hex
  }

  let(:value) {
    {:sample_key => 'sample-value', :user => {:id => 'john-doe'}}
  }

  let(:redis) {
    double(:redis_instance)
  }

  let(:store) {
    Rack::Session::Redis::RedisSessionStore.new(:default_expiration => 3600, :key_prefix => PREFIX, :redis => redis)
  }

  before do
    allow(redis).to receive(:exists).and_return(false)
    allow(redis).to receive(:get).and_return(Marshal.dump(value))
    allow(redis).to receive(:setnx).and_return(true)
    allow(redis).to receive(:setex)
    allow(redis).to receive(:set)
    allow(redis).to receive(:del).and_return(1)
  end

  it 'should throw exception from constructor if the :default_expiration option is not specified' do
    expect { Rack::Session::Redis::RedisSessionStore.new({}) }.to raise_error ArgumentError
  end

  it 'should invoke redis.exists with a prefix' do
    expect(redis).to receive(:exists).with(PREFIX + key)
    expect(store.exists?(key)).to be_falsey
  end

  it 'should invoke redis.get with a prefix and return unmarshalled value' do
    expect(redis).to receive(:get).with(PREFIX + key)
    expect(store.load(key)).to eq(value)
  end

  it 'should invoke get/del with a prefix when invalidating the key' do
    expect(redis).to receive(:get).with(PREFIX + key)
    expect(redis).to receive(:del).with(PREFIX + key)
    store.invalidate(key)
  end

  it 'should invoke redis.setnx with a prefix' do
    expect(redis).to receive(:setnx).with(PREFIX + key, Marshal.dump(value))
    expect(store.create(key, value)).to be_truthy
  end

  it 'should return unmarshalled data' do
    expect(store.load(key)).to eq(value)
    expect(store.invalidate(key)).to eq(value)
  end

  it 'should send to redis already marshalled value on store and create' do
    expect(redis).to receive(:setex).with(PREFIX + key, 3600, Marshal.dump(value))
    expect(redis).to receive(:setnx).with(PREFIX + key, Marshal.dump(value))
    store.store(key, value)
    store.create(key, value)
  end

  it 'should invoke redis.set instead of redis.setex if the expiration is less than or equal 0 (meaning no expiration)' do
    expect(redis).to receive(:set).with(PREFIX + key, Marshal.dump(value))
    store.store(key, value, :expire_after => 0)
  end

  it 'should set default expiration if :expire_after option not specified' do
    store = Rack::Session::Redis::RedisSessionStore.new(:default_expiration => 1234, :key_prefix => PREFIX, redis: redis)
    expect(redis).to receive(:setex).with(anything, 1234, anything)
    store.store(key, value)
  end

end
