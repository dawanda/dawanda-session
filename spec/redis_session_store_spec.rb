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

  let(:store) {
    Rack::Session::Redis::RedisSessionStore.new(:default_expiration => 3600, :key_prefix => PREFIX)
  }

  let(:redis) {
    double(:redis_instance)
  }

  before do
    allow(Redis).to receive(:new).and_return(redis)
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
    store = Rack::Session::Redis::RedisSessionStore.new(:default_expiration => 1234, :key_prefix => PREFIX)
    expect(redis).to receive(:setex).with(anything, 1234, anything)
    store.store(key, value)
  end

  context 'when Redis is down' do
    before do
      allow(redis).to receive(:exists) { raise Redis::BaseError }
      allow(redis).to receive(:get) { raise Redis::BaseError }
      allow(redis).to receive(:set) { raise Redis::BaseError }
      allow(redis).to receive(:setex) { raise Redis::BaseError }
      allow(redis).to receive(:setnx) { raise Redis::BaseError }
      allow(redis).to receive(:del) { raise Redis::BaseError }
    end

    describe '#exists?' do
      it 'returns false' do
        expect(store.exists?('foo')).to eq(false)
      end
    end

    describe '#load' do
      it 'returns an empty session hash, marked as fake' do
        expect(store.load('foo')).to eq({ dummy: true })
      end
    end

    describe '#store' do
      it 'returns nil' do
        expect(store.store('foo', { foo: 'bar' })).to be_nil
      end
    end

    describe '#create' do
      it 'returns nil' do
        expect(store.create('foo', { foo: 'bar' })).to be_nil
      end
    end

    describe '#invalidate' do
      it 'returns nil' do
        expect(store.invalidate('foo')).to be_nil
      end
    end

    context 'when Bugsnag is defined' do
      around do |example|
        begin
          class Bugsnag; end
          example.run
        ensure
          Object.send(:remove_const, :Bugsnag)
        end
      end

      [:exists?, :load, :invalidate].each do |method|
        describe method do
          it 'logs Redis exceptions to Bugsnag' do
            expect(Bugsnag).to receive(:notify).with an_instance_of(::Redis::BaseError)
            store.send(method, 'foo')
          end
        end
      end

      [:store, :create].each do |method|
        describe method do
          it 'logs Redis exceptions to Bugsnag' do
            expect(Bugsnag).to receive(:notify).with an_instance_of(::Redis::BaseError)
            store.send(method, 'foo', { foo: 'bar' })
          end
        end
      end
    end
  end
end
