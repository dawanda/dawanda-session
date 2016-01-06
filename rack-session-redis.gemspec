# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/session/redis/version'

Gem::Specification.new do |spec|
  spec.name          = "loveos-rack-session-redis"
  spec.version       = Rack::Session::Redis::VERSION
  spec.authors       = ["Adrian Wolny"]
  spec.email         = ["adrian.wolny@yahoo.com"]
  spec.summary       = %q{Rack::Session::Redis::SessionService provides simple cookie based session management.}
  spec.description   = %q{SessionService provides simple cookie based session management. Session data is stored in Redis.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'loveos-common'
  spec.add_dependency 'rack'
  spec.add_dependency 'redis'
  spec.add_dependency 'dawanda-statsd-client'
end
