module FeedParsers
  class WordpressJsonParser < BaseParser
    def parse
      content = fetch_content
      posts = JSON.parse(content)

      # WordPress REST API returns an array of posts
      unless posts.is_a?(Array)
        raise "Invalid WordPress JSON response"
      end

      entries = posts.map do |post|
        normalize_entry(extract_entry_data(post))
      end

      {
        title: @feed&.name || "WordPress Blog",
        description: @feed&.description,
        url: @feed&.url || extract_site_url,
        entries: entries,
        last_modified: nil,
        etag: nil
      }
    rescue JSON::ParserError => e
      raise "Invalid JSON format: #{e.message}"
    rescue => e
      raise "Error parsing WordPress JSON: #{e.message}"
    end

    private

    def extract_entry_data(post)
      {
        title: extract_title(post),
        url: post["link"],
        guid: post["guid"]&.dig("rendered") || post["id"].to_s,
        summary: extract_excerpt(post),
        content: extract_content(post),
        published_at: post["date"] || post["date_gmt"],
        author: extract_author_name(post),
        enclosure_url: extract_featured_media(post),
        duration: nil
      }
    end

    def extract_title(post)
      title = post["title"]
      title.is_a?(Hash) ? title["rendered"] : title
    end

    def extract_excerpt(post)
      excerpt = post["excerpt"]
      excerpt.is_a?(Hash) ? excerpt["rendered"] : excerpt
    end

    def extract_content(post)
      content = post["content"]
      content.is_a?(Hash) ? content["rendered"] : content
    end

    def extract_author_name(post)
      # WordPress might include embedded author data
      if post["_embedded"] && post["_embedded"]["author"]
        post["_embedded"]["author"].first["name"]
      else
        nil
      end
    end

    def extract_featured_media(post)
      # WordPress might include embedded media data
      if post["_embedded"] && post["_embedded"]["wp:featuredmedia"]
        media = post["_embedded"]["wp:featuredmedia"].first
        media["source_url"] if media
      else
        nil
      end
    end

    def extract_site_url
      # Try to extract base URL from feed URL
      uri = URI.parse(@feed_url)
      "#{uri.scheme}://#{uri.host}"
    rescue
      nil
    end

    def fetch_content
      # For WordPress JSON API, we might need to add parameters
      url = @feed_url
      url += (url.include?("?") ? "&" : "?") + "_embed=1&per_page=20"

      response = Faraday.new do |f|
        f.use Faraday::Retry::Middleware, max: 2
        f.adapter Faraday.default_adapter
        f.headers["User-Agent"] = "Ruby Feed Parser/1.0"
        f.headers["Accept"] = "application/json"
        f.options.timeout = 30
        f.options.open_timeout = 10
      end.get(url)

      raise "HTTP Error: #{response.status}" unless response.success?

      response.body
    rescue Faraday::Error => e
      raise "Network error fetching WordPress JSON: #{e.message}"
    end
  end
end
