# Rack::Session::Redis

*Rack::Session::Redis::SessionService* provides simple cookie based session management.
Session data is stored in Redis and the corresponding session key is maintained in the cookie.
You may treat SessionService as you would Rack::Session::Pool.

You can use all options supported by *Rack::Session::Abstract::ID*.

## Installation

Add this line to your application's Gemfile:

    gem 'loveos-rack-session-redis'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install loveos-rack-session-redis

## Usage

```
use Rack::Session::Redis::SessionService,
    key: 'my_session_key',
    domain: 'example.com',
    path: '/',
    expire_after: 3600,
    redis_options: {host: 'redis-master.example.com', port: 6379, db: 13},
    key_prefix: 'my:session:'
```