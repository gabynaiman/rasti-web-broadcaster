require 'coverage_helper'
require 'minitest/autorun'
require 'minitest/colorin'
require 'pry-nav'
require 'rasti-web-broadcaster'
require 'rack/test'

Rasti::Web::Broadcaster.configure do |config|
  config.logger = Logger.new '/dev/null'
  config.keep_alive_interval = 0.1
end