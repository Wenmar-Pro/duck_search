require "test_helper"

class DuckSearch::ClientTest < Minitest::Test
  def test_search_returns_capped_results
    VCR.use_cassette("ddg_results") do
      client = DuckSearch::Client.new
      results = client.search("FG0326")

      assert_equal 5, results.count
      assert_instance_of DuckSearch::Result, results.first
      refute_empty results.first.title
      assert_includes results.first.description, "Fuel Pump"
    end
  end

  def test_search_returns_results_for_automotive_part
    VCR.use_cassette("ddg_904_101_automotive_part") do
      results = DuckSearch::Client.new.search("904-101 automotive part")

      assert_predicate results.count, :positive?,
        "Expected results for '904-101 automotive part', got 0"
      assert_instance_of DuckSearch::Result, results.first
      refute_empty results.first.title
      assert_match %r{^https?://}, results.first.url
    end
  end

  def test_search_decodes_urls
    VCR.use_cassette("ddg_results") do
      results = DuckSearch::Client.new.search("FG0326")
      refute_empty results
      results.each { |r| assert_match %r{^https?://}, r.url }
    end
  end

  def test_search_returns_empty_array_on_no_results
    VCR.use_cassette("ddg_no_results") do
      results = DuckSearch::Client.new.search("xylophone_zebra_quantum_1234567890")
      assert_equal [], results
    end
  end

  def test_search_raises_bot_error_on_anomaly
    VCR.use_cassette("ddg_anomaly") do
      error = assert_raises DuckSearch::BotError do
        DuckSearch::Client.new.search("904-101 automotive part")
      end
      assert_includes error.message, "anti-bot"
    end
  end

  def test_search_raises_http_error_on_503
    stub_request(:get, "https://html.duckduckgo.com/html?q=test&b=&kf=-1&kh=1&kp=1&k1=-1")
      .to_return(status: 503).times(4)

    assert_raises DuckSearch::HttpError do
      DuckSearch::Client.new.search("test")
    end
  end

  def test_search_retries_on_503_then_succeeds
    body = <<~HTML
      <html><body>
        <div class="result">
          <a class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com%2Fpart">Example Part</a>
          <span class="result__snippet">Description.</span>
        </div>
      </body></html>
    HTML

    stub_request(:get, "https://html.duckduckgo.com/html?q=test&b=&kf=-1&kh=1&kp=1&k1=-1")
      .to_return(status: 503).then
      .to_return(body: body, status: 200)

    results = DuckSearch::Client.new.search("test")
    assert_equal 1, results.count
  end
end
