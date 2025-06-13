# Rasti::Web::Broadcaster

[![Gem Version](https://badge.fury.io/rb/rasti-web-broadcaster.svg)](https://rubygems.org/gems/rasti-web-broadcaster)
[![CI](https://github.com/gabynaiman/rasti-web-broadcaster/actions/workflows/ci.yml/badge.svg)](https://github.com/gabynaiman/rasti-web-broadcaster/actions/workflows/ci.yml)

Enable server sent events with rack middleware implemented over Faye and Broadcaster (Redis Pub/Sub)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rasti-web-broadcaster'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rasti-web-broadcaster

## Usage

### Configuration
```ruby
Rasti::Web::Broadcaster.configure do |config|
  config.id = 'AppName'
  config.redis_settings = "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}"
  config.keep_alive_interval = 30
  config.logger = Logger.new "/log/#{ENV['RACK_ENV']}.log"
end
```

### Rack middleware
```ruby
use Rasti::Web::Broadcaster

headers = {'Access-Control-Allow-Origin' => '*'}
use Rasti::Web::Broadcaster, headers
```

### Publishing events from the web
```ruby
Rasti::Web::Broadcaster.publish channel_id, data:  'hello'      # string or json
                                            event: 'eventName', # optional
                                            id:    1234         # optional
```

### Publishing events from external processes
```ruby
require 'broadcaster'

broadcaster = Broadcaster.new id: 'AppName', redis_settings: "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}"

broadcaster.publish channel_id, data: 'hello'
```

### Client subscription (browser)
```javascript
const events = new EventSource('/channel');

events.addEventListener('open', e => console.info('Started streaming')); 

events.addEventListener('error', e => console.warn(e)); 

events.onmessage = e => console.debug(e.data)

events.addEventListener('eventName', e => console.debug(e.data));
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gabynaiman/rasti-web-broadcaster.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

