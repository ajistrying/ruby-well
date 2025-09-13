module FeedParsers
  class JsonFeedParser < BaseParser
    def parse
      content = fetch_content
      json_feed = JSON.parse(content)
      
      validate_json_feed!(json_feed)
      
      entries = (json_feed['items'] || []).map do |item|
        normalize_entry(extract_entry_data(item))
      end
      
      {
        title: json_feed['title'],
        description: json_feed['description'],
        url: json_feed['home_page_url'] || json_feed['feed_url'],
        entries: entries,
        last_modified: nil,
        etag: nil
      }
    rescue JSON::ParserError => e
      raise "Invalid JSON format: #{e.message}"
    rescue => e
      raise "Error parsing JSON feed: #{e.message}"
    end

    private

    def validate_json_feed!(json_feed)
      unless json_feed['version']&.start_with?('https://jsonfeed.org/version/')
        raise "Not a valid JSON Feed format"
      end
    end

    def extract_entry_data(item)
      {
        title: item['title'],
        url: item['url'] || item['external_url'],
        guid: item['id'],
        summary: item['summary'],
        content: extract_content(item),
        published_at: item['date_published'] || item['date_modified'],
        author: extract_author(item),
        enclosure_url: extract_attachment(item),
        duration: extract_duration(item)
      }
    end

    def extract_content(item)
      item['content_html'] || item['content_text'] || item['summary']
    end

    def extract_author(item)
      author = item['author'] || item['authors']&.first
      return nil unless author
      
      author['name'] if author.is_a?(Hash)
    end

    def extract_attachment(item)
      attachment = item['attachments']&.first
      return nil unless attachment
      
      attachment['url']
    end

    def extract_duration(item)
      attachment = item['attachments']&.first
      return nil unless attachment
      
      attachment['duration_in_seconds']
    end
  end
end