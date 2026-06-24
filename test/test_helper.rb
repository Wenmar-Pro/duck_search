require "bundler/setup"
require "minitest/autorun"
require "minitest/spec"
require "vcr"
require "webmock/minitest"
require "logger"

VCR.configure do |config|
  config.cassette_library_dir = File.join(__dir__, "duck_search", "fixtures", "vcr")
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
  config.allow_http_connections_when_no_cassette = false
end

unless defined?(Rails)
  module Rails
    def self.logger
      @logger ||= Logger.new(File::NULL)
    end
  end
end

require "duck_search"
