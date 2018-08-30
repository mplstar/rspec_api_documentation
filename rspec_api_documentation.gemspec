# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
# $:.unshift lib unless $:.include?(lib)
require 'rspec_api_documentation/version'

Gem::Specification.new do |s|
  s.name        = "rspec_api_documentation"
  s.version     = RspecApiDocumentation::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chris Cahoon", "Sam Goldman", "Eric Oestrich", "Xiaofeng Cheng"]
  s.email       = ["chris@smartlogicsolutions.com", "sam@smartlogicsolutions.com", "eric@smartlogicsolutions.com", "truecolour@gmail.com"]
  s.summary     = "A double black belt for your docs"
  s.description = "Generate API docs from your test suite"
  s.homepage    = "http://smartlogicsolutions.com"
  s.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if s.respond_to?(:metadata)
    s.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  s.required_rubygems_version = ">= 2.4.5"

  # If adding, please consider gemfiles/minimum_dependencies
  s.add_runtime_dependency "rspec", "~> 3.0"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "i18n", "~> 1.0"
  s.add_runtime_dependency "mustache", "~> 1.0", ">= 0.99.4"
  s.add_runtime_dependency "webmock", "~> 3.0"
  s.add_runtime_dependency "json", "~> 2.0"

  s.add_development_dependency "bundler", "~> 1.0"
  s.add_development_dependency "fakefs", "<= 0.13.3"
  s.add_development_dependency "sinatra", "~> 2.0"
  s.add_development_dependency "aruba"
  s.add_development_dependency "capybara", "< 3.2.0"
  s.add_development_dependency "rake", "~> 12.0"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rack-oauth2"

  s.files         = Dir.glob("lib/**/*") + Dir.glob("templates/**/*")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.bindir        = "exe"
  s.require_paths = ['lib']
  # s.files     = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
end

