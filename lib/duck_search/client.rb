require "uri"
require "cgi"
require "faraday/retry"
require "faraday/gzip"

module DuckSearch
  class Client
    BASE_URL     = "https://html.duckduckgo.com"
    SEARCH_PATH  = "/html"
    RESULT_CAP   = 5

    # Match ddgr's actual User-Agent exactly
    DEFAULT_USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " \
                         "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    attr_reader :proxy, :timeout, :open_timeout, :user_agent

    def initialize(proxy: nil, timeout: 15, open_timeout: 10, user_agent: DEFAULT_USER_AGENT)
      @proxy        = proxy
      @timeout      = timeout
      @open_timeout = open_timeout
      @user_agent   = user_agent
    end

    def search(query)
      # POST form body matching ddgr's page-0 payload
      form_data = {
        q:  query,
        b:  "",        # required blank field
        kf: "-1",      # disable favicons
        kh: "1",       # HTTPS always on
        kl: "us-en",   # region
        kp: "1",       # safe search (use -2 to disable)
        k1: "-1",      # ads off
      }

      response = connection.post(SEARCH_PATH) do |req|
        req.headers["User-Agent"]      = user_agent
        req.headers["Accept-Encoding"] = "gzip, deflate"
        req.headers["Accept"]          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        req.headers["Accept-Language"] = "en-US,en;q=0.9"
        req.headers["DNT"]             = "1"
        req.headers["Content-Type"]    = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(form_data)
      end

      unless response.success?
        raise HttpError.new("DuckDuckGo returned HTTP #{response.status}",
                            status: response.status,
                            url: "#{BASE_URL}#{SEARCH_PATH}")
      end

      parse_html(response.body)
    rescue Faraday::Error => e
      raise HttpError.new("DuckDuckGo connection failed: #{e.message}",
                          url: "#{BASE_URL}#{SEARCH_PATH}")
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.proxy = proxy if proxy
        f.request :gzip
        # Don't auto-retry on bot-detection responses — back off manually instead
        f.request :retry, max: 2, interval: 1.0, backoff_factor: 2,
                  retry_statuses: [429, 500, 502, 503, 504],
                  methods: [:post]
        f.options.timeout      = timeout
        f.options.open_timeout = open_timeout
        f.adapter Faraday.default_adapter
      end
    end

    def parse_html(html_body)
      return [] if html_body.nil? || html_body.strip.empty?

      doc = Nokogiri::HTML(html_body)

      if doc.at_css(".anomaly-modal__mask") || html_body.include?("anomaly-modal")
        raise BotError, "DuckDuckGo returned an anti-bot challenge page"
      end

      results = doc.css(".result").map do |node|
        anchor       = node.at_css(".result__a")
        snippet_node = node.at_css(".result__snippet")
        next unless anchor

        DuckSearch::Result.new(
          title:       anchor.text.strip,
          description: snippet_node&.text&.strip || "",
          url:         clean_url(anchor["href"])
        )
      end.compact

      results.first(RESULT_CAP)
    end

    def clean_url(href)
      return nil if href.nil? || href.strip.empty?

      if href.include?("uddg=")
        parsed = URI.parse(href.start_with?("http") ? href : "https:#{href}")
        params = URI.decode_www_form(parsed.query || "")
        uddg   = params.find { |k, _| k == "uddg" }
        uddg ? CGI.unescape(uddg[1]) : href
      else
        href.strip
      end
    rescue URI::InvalidURIError
      href
    end
  end
end
