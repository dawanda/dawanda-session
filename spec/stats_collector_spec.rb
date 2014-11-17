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
    begin
      client.with_stats do
        raise Redis::TimeoutError
      end
    rescue
    end
  end

  it 'should re-raise Redis::TimeoutError if timeout occurred during invocation of the block' do
    expect(client).to receive(:statsd_client).and_return(statsd_client)
    expect(statsd_client).to receive(:increment)
    expect {
      client.with_stats do
        raise Redis::TimeoutError
      end
    }.to raise_error Redis::TimeoutError
  end
end