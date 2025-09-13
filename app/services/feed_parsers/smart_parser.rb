module FeedParsers
  class SmartParser
    attr_reader :feed_url, :feed

    def initialize(feed_url, feed = nil)
      @feed_url = feed_url
      @feed = feed
    end

    def parse
      parser = detect_parser
      parser.parse
    rescue => e
      # Log the error with the specific parser that failed
      Rails.logger.error "Feed parsing failed for #{feed_url}: #{e.message}"

      # Try fallback parsers if primary fails
      fallback_parse
    end

    private

    def detect_parser
      case @feed_url
      when /wp-json\/wp\/v2/i
        WordpressJsonParser.new(@feed_url, nil, @feed)
      when /\.json$/i, /\/feed\.json/i
        JsonFeedParser.new(@feed_url, nil, @feed)
      when /sitemap\.xml$/i
        SitemapParser.new(@feed_url, nil, @feed)
      else
        # Default to RSS/Atom parser for most feeds
        RssAtomParser.new(@feed_url, nil, @feed)
      end
    end

    def fallback_parse
      # Try parsers in order of likelihood
      parsers = [
        RssAtomParser,
        JsonFeedParser,
        WordpressJsonParser,
        SitemapParser
      ]

      errors = []

      parsers.each do |parser_class|
        begin
          parser = parser_class.new(@feed_url, nil, @feed)
          result = parser.parse

          # If we got some entries, consider it successful
          return result if result[:entries].present?
        rescue => e
          errors << "#{parser_class.name}: #{e.message}"
          next
        end
      end

      # If all parsers failed, raise an error with details
      raise "All parsers failed for #{@feed_url}:\n#{errors.join("\n")}"
    end
  end
end
