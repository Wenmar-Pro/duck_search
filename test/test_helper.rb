require "bundler/setup"
require "minitest/autorun"
require "minitest/spec"
require "webmock/minitest"
require "logger"

unless defined?(Rails)
  module Rails
    def self.logger
      @logger ||= Logger.new(File::NULL)
    end
  end
end

require "duck_search"
