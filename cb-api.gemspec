lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cb/client/version'

Gem::Specification.new do |s|
  s.name = "cb-api"
  s.version = CB::Client::VERSION
  s.authors = ["Adrien THERY", "Nicolas NARDONE", "Sebastien NEUSCH"]
  s.email = 'contact@contentbird.com'
  s.summary = "Ruby wrapper for ContentBird HTTP API"
  s.homepage = "http://github.com/contentbird/cb-api"
  s.license = ""

  s.add_runtime_dependency     'faraday',     '>= 0.8.8'

  s.add_development_dependency 'rspec'

  s.files                 = `git ls-files`.split("\n")
  s.test_files            = `git ls-files -- spec/*`.split("\n")
  s.require_paths         = ["lib"]
  s.required_ruby_version = '>= 1.9.3'
end
