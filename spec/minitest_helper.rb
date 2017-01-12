require 'coverage_helper'
require 'minitest/autorun'
require 'minitest/colorin'
require 'pry-nav'
require 'rasti-web-broadcaster'
require 'rack/test'

Rasti::Web::Broadcaster.logger.level = Logger::ERROR