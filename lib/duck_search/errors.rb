module DuckSearch
  class Error < StandardError; end

  class HttpError < Error
    attr_reader :status, :url

    def initialize(message = nil, status: nil, url: nil)
      @status = status
      @url = url
      super(message || "DuckDuckGo request failed (HTTP #{status})")
    end
  end

  class ParseError < Error; end

  class BotError < Error; end
end
