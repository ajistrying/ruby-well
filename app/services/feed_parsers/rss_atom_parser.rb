require 'feedjira'

module FeedParsers
  class RssAtomParser < BaseParser
    def parse
      content = fetch_content
      parsed_feed = Feedjira.parse(content)
      
      raise "Invalid feed format" unless parsed_feed.respond_to?(:entries)
      
      entries = parsed_feed.entries.map do |entry|
        normalize_entry(extract_entry_data(entry))
      end
      
      {
        title: parsed_feed.title,
        description: parsed_feed.respond_to?(:description) ? parsed_feed.description : nil,
        url: parsed_feed.url,
        entries: entries,
        last_modified: parsed_feed.respond_to?(:last_modified) ? parsed_feed.last_modified : (parsed_feed.respond_to?(:last_built) ? parsed_feed.last_built : nil),
        etag: parsed_feed.respond_to?(:etag) ? parsed_feed.etag : nil
      }
    rescue Feedjira::NoParserAvailable => e
      raise "Feed format not supported: #{e.message}"
    rescue => e
      raise "Error parsing RSS/Atom feed: #{e.message}"
    end

    private

    def extract_entry_data(entry)
      {
        title: entry.title,
        url: extract_url(entry),
        guid: entry.entry_id || entry.guid || entry.id,
        summary: extract_summary(entry),
        content: extract_content(entry),
        published_at: entry.published || entry.updated,
        author: extract_author(entry),
        enclosure_url: extract_enclosure(entry),
        duration: extract_duration(entry)
      }
    end

    def extract_url(entry)
      # Try different URL field names
      if entry.respond_to?(:url) && entry.url
        entry.url
      elsif entry.respond_to?(:link) && entry.link
        entry.link
      elsif entry.respond_to?(:links) && entry.links.is_a?(Array)
        entry.links.first
      else
        nil
      end
    end

    def extract_summary(entry)
      # Handle different summary field names
      if entry.respond_to?(:summary)
        entry.summary
      elsif entry.respond_to?(:description)
        entry.description
      else
        nil
      end
    end

    def extract_content(entry)
      # Try different content fields in order of preference
      if entry.respond_to?(:content)
        entry.content
      elsif entry.respond_to?(:description)
        entry.description
      elsif entry.respond_to?(:summary)
        entry.summary
      else
        nil
      end
    end

    def extract_author(entry)
      case entry.author
      when String
        entry.author
      when Hash
        entry.author[:name] || entry.author['name']
      else
        nil
      end
    end

    def extract_enclosure(entry)
      return nil unless entry.respond_to?(:enclosure_url)
      entry.enclosure_url
    end

    def extract_duration(entry)
      # For podcast feeds, extract duration from iTunes tags
      if entry.respond_to?(:itunes_duration)
        parse_duration(entry.itunes_duration)
      elsif entry.respond_to?(:duration)
        parse_duration(entry.duration)
      else
        nil
      end
    end

    def parse_duration(duration_string)
      return nil if duration_string.blank?
      
      # Handle different duration formats (HH:MM:SS, MM:SS, or seconds)
      case duration_string.to_s
      when /^(\d+):(\d+):(\d+)$/
        $1.to_i * 3600 + $2.to_i * 60 + $3.to_i
      when /^(\d+):(\d+)$/
        $1.to_i * 60 + $2.to_i
      when /^\d+$/
        duration_string.to_i
      else
        nil
      end
    end
  end
end