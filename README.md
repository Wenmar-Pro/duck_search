# DuckSearch

Lightweight DuckDuckGo HTML search client. Fetches and parses DuckDuckGo's no-JS HTML search endpoint, returning titles, snippets, and decoded URLs. No API key required.

## Usage

```ruby
client = DuckSearch::Client.new
results = client.search("FG0326 specifications")
results.each do |r|
  puts "#{r.title} - #{r.url}"
end
```
