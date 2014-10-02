require 'rack/session/redis/stats_collector'
require 'statsd/client'
require 'redis/errors'

describe Rack::Session::Redis::StatsCollector do
  let(:client) do
    c = Class.new do
      include Rack::Session::Redis::StatsCollector
    end
    c.new
  end

  let(:statsd_client) do
    double(:statsd_client)
  end

  it 'should correctly parse host and port' do
    expect(Statsd::Client).to receive(:new).with('statsd', 8125)

    client.statsd_client('statsd:8125')
  end

  it 'should increase the timeout counter on TimeoutError' do
    expect(client).to receive(:statsd_client).and_return(statsd_client)
    expect(statsd_client).to receive(:increment).with(Rack::Session::Redis::StatsCollector::TIMEOUT_COUNTER)

    expect {
      client.with_stats do
        raise Redis::TimeoutError
      end
    }.to raise_error Redis::TimeoutError
  end

  it 'should measure the time of invocation' do
    expect(client).to receive(:statsd_client).and_return(statsd_client)
    duration = 1000
    expect(statsd_client).to receive(:timing).with(Rack::Session::Redis::StatsCollector::REQUEST_DURATION, be_between(1000, 2000))

    client.with_stats do
      sleep(1)
    end
  end
end