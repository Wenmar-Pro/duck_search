Gem::Specification.new do |spec|
  spec.name          = "duck_search"
  spec.version       = "0.1.1"
  spec.authors       = ["Wenmar Pro"]
  spec.summary       = "Lightweight DuckDuckGo HTML search client"
  spec.description   = "Fetches and parses DuckDuckGo's no-JS HTML search results. Returns titles, snippets, and URLs. No API key required."
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]
  spec.add_dependency "faraday", ">= 2.0"
  spec.add_dependency "faraday-retry", ">= 2.0"
  spec.add_dependency "faraday-gzip", "~> 3"
  spec.add_dependency "nokogiri", ">= 1.16"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "base64"
  spec.add_development_dependency "irb", "~> 1.18.0"
end
