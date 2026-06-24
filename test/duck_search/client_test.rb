require "test_helper"

class DuckSearch::ClientTest < Minitest::Test
  def test_search_returns_capped_results
    stub_request(:post, "https://html.duckduckgo.com/html")
      .to_return(body: File.read(File.join(__dir__, "fixtures", "results.html")), status: 200)

    client = DuckSearch::Client.new
    results = client.search("FG0326")

    assert_equal 5, results.count
    assert_instance_of DuckSearch::Result, results.first
    assert_equal "Delphi FG0326 Fuel Pump Module Assembly", results.first.title
    assert_includes results.first.description, "Fuel Pump"
  end

  def test_search_decodes_uddg_redirect
    html = <<~HTML
      <html><body>
        <div class="result">
          <a class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fwww.example.com%2Fpart">Example Part</a>
          <span class="result__snippet">A part description.</span>
        </div>
      </body></html>
    HTML

    stub_request(:post, "https://html.duckduckgo.com/html")
      .to_return(body: html, status: 200)

    client = DuckSearch::Client.new
    results = client.search("test")

    assert_equal "https://www.example.com/part", results.first.url
  end

  def test_search_raises_http_error_on_503
    stub_request(:post, "https://html.duckduckgo.com/html")
      .to_return(status: 503).times(4) # retry middleware retries 2x + original

    client = DuckSearch::Client.new

    assert_raises DuckSearch::HttpError do
      client.search("test")
    end
  end

  def test_search_returns_empty_array_on_no_results
    html = "<html><body></body></html>"
    stub_request(:post, "https://html.duckduckgo.com/html")
      .to_return(body: html, status: 200)

    client = DuckSearch::Client.new
    results = client.search("noresults")

    assert_equal [], results
  end

  def test_search_sends_post_with_form_body
    stub = stub_request(:post, "https://html.duckduckgo.com/html")
      .with(
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        body: /q=test\+query/
      )
      .to_return(body: "<html><body></body></html>", status: 200)

    DuckSearch::Client.new.search("test query")

    assert_requested stub
  end

  def test_search_sends_dnt_header
    stub = stub_request(:post, "https://html.duckduckgo.com/html")
      .with(headers: { "DNT" => "1" })
      .to_return(body: "<html><body></body></html>", status: 200)

    DuckSearch::Client.new.search("test")

    assert_requested stub
  end

  def test_search_retries_on_503_then_succeeds
    stub_request(:post, "https://html.duckduckgo.com/html")
      .to_return(status: 503).then
      .to_return(body: File.read(File.join(__dir__, "fixtures", "results.html")), status: 200)

    client = DuckSearch::Client.new
    results = client.search("FG0326")

    assert_equal 5, results.count
  end
end
