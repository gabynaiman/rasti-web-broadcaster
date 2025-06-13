# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rasti/web/broadcaster/version'

Gem::Specification.new do |spec|
  spec.name          = 'rasti-web-broadcaster'
  spec.version       = Rasti::Web::Broadcaster::VERSION
  spec.authors       = ['Gabriel Naiman']
  spec.email         = ['gabynaiman@gmail.com']
  spec.summary       = 'Rack middleware for server sent events'
  spec.description   = 'Enable server sent events with rack middleware implemented over Faye and Broadcaster (Redis Pub/Sub)'
  spec.homepage      = 'https://github.com/gabynaiman/rasti-web-broadcaster'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'faye-websocket', '~> 0.11'
  spec.add_runtime_dependency 'broadcaster', '~> 1.0', '>= 1.0.2'
  spec.add_runtime_dependency 'class_config', '~> 0.0'

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'minitest', '~> 5.0', '< 5.11'
  spec.add_development_dependency 'minitest-colorin', '~> 0.1'
  spec.add_development_dependency 'minitest-line', '~> 0.6'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'pry-nav', '~> 0.2'
  spec.add_development_dependency 'rack-test', '~> 0.6'
end