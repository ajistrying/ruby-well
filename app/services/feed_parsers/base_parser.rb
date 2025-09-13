module FeedParsers
  class BaseParser
    attr_reader :feed_url, :content, :feed

    def initialize(feed_url, content = nil, feed = nil)
      @feed_url = feed_url
      @content = content
      @feed = feed
    end

    def parse
      raise NotImplementedError, "Subclasses must implement parse method"
    end

    protected

    def normalize_entry(entry_data)
      {
        title: sanitize_text(entry_data[:title]),
        url: entry_data[:url],
        guid: entry_data[:guid] || generate_guid(entry_data),
        summary: sanitize_html(entry_data[:summary]),
        content: sanitize_html(entry_data[:content]),
        published_at: parse_date(entry_data[:published_at]),
        author: sanitize_text(entry_data[:author]),
        enclosure_url: entry_data[:enclosure_url],
        duration: entry_data[:duration]
      }
    end

    def sanitize_text(text)
      return nil if text.blank?
      text.to_s.strip
    end

    def sanitize_html(html)
      return nil if html.blank?
      Loofah.fragment(html.to_s).scrub!(:whitewash).to_s.strip
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      begin
        case date_string
        when Time, DateTime, Date
          date_string.to_datetime
        when String
          DateTime.parse(date_string)
        else
          nil
        end
      rescue ArgumentError, TypeError
        nil
      end
    end

    def generate_guid(entry_data)
      # Generate a consistent GUID based on URL and title
      if entry_data[:url].present?
        Digest::SHA256.hexdigest("#{entry_data[:url]}#{entry_data[:title]}")
      else
        nil
      end
    end

    def fetch_content
      return @content if @content.present?

      response = Faraday.new do |f|
        f.use Faraday::Retry::Middleware, max: 2
        f.adapter Faraday.default_adapter
        f.headers["User-Agent"] = "Ruby Feed Parser/1.0"
        f.options.timeout = 30
        f.options.open_timeout = 10
      end.get(@feed_url)

      raise "HTTP Error: #{response.status}" unless response.success?

      @content = response.body
    rescue Faraday::Error => e
      raise "Network error fetching feed: #{e.message}"
    end
  end
end
