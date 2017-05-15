# Rasti::Web::Broadcaster

[![Gem Version](https://badge.fury.io/rb/rasti-web-broadcaster.svg)](https://rubygems.org/gems/rasti-web-broadcaster)
[![Build Status](https://travis-ci.org/gabynaiman/rasti-web-broadcaster.svg?branch=master)](https://travis-ci.org/gabynaiman/rasti-web-broadcaster)
[![Coverage Status](https://coveralls.io/repos/gabynaiman/rasti-web-broadcaster/badge.svg?branch=master)](https://coveralls.io/r/gabynaiman/rasti-web-broadcaster?branch=master)
[![Code Climate](https://codeclimate.com/github/gabynaiman/rasti-web-broadcaster.svg)](https://codeclimate.com/github/gabynaiman/rasti-web-broadcaster)
[![Dependency Status](https://gemnasium.com/gabynaiman/rasti-web-broadcaster.svg)](https://gemnasium.com/gabynaiman/rasti-web-broadcaster)

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
  config.logger = Logger.new "/log/#{ENV['RACK_ENV']}.log"
end
```

### Rack middleware
```ruby
use Rasti::Web::Broadcaster
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

