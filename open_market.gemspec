# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'open_market/version'

Gem::Specification.new do |spec|
  spec.name          = "openmarket"
  spec.version       = OpenMarket::VERSION
  spec.authors       = ["Isaac Betesh"]
  spec.email         = ["iybetesh@gmail.com"]
  spec.summary       = "Send SMS messages using the OpenMarket API"
  spec.description   = `cat README.md`
  spec.homepage      = "https://github.com/betesh/open_market"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3"

  spec.add_dependency "sms_validation", "~> 0.0.2"
end
