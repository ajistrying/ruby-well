require "nokogiri"

module FeedParsers
  class SitemapParser < BaseParser
    def parse
      content = fetch_content
      doc = Nokogiri::XML(content)

      # Remove namespaces for easier parsing
      doc.remove_namespaces!

      # Try to find URLs with lastmod dates
      urls = extract_urls_from_sitemap(doc)

      # Filter and sort by date, get recent entries
      recent_urls = urls
        .select { |u| u[:lastmod].present? }
        .sort_by { |u| u[:lastmod] }
        .reverse
        .first(20)

      entries = recent_urls.map do |url_data|
        normalize_entry(url_data)
      end

      {
        title: @feed&.name || "Sitemap Feed",
        description: @feed&.description,
        url: @feed&.url || extract_site_url,
        entries: entries,
        last_modified: nil,
        etag: nil
      }
    rescue => e
      raise "Error parsing sitemap: #{e.message}"
    end

    private

    def extract_urls_from_sitemap(doc)
      urls = []

      # Check if it's a sitemap index
      if doc.xpath("//sitemapindex").any?
        # It's a sitemap index, we'd need to fetch sub-sitemaps
        # For now, we'll skip these
        return []
      end

      # Extract URLs from regular sitemap
      doc.xpath("//url").each do |url_node|
        loc = url_node.xpath("loc").text
        lastmod = url_node.xpath("lastmod").text

        # Try to filter for blog/article URLs
        next unless looks_like_article?(loc)

        urls << {
          title: extract_title_from_url(loc),
          url: loc,
          guid: loc,
          summary: nil,
          content: nil,
          published_at: lastmod.present? ? parse_date(lastmod) : nil,
          author: nil,
          enclosure_url: nil,
          duration: nil,
          lastmod: parse_date(lastmod)
        }
      end

      urls
    end

    def looks_like_article?(url)
      # Simple heuristic to identify blog/article URLs
      url.match?(/\/(blog|article|post|entry|news|story)s?\//i) ||
      url.match?(/\d{4}\/\d{1,2}/) || # Date pattern like 2024/01
      url.match?(/\/([\w-]+)$/) # Slug at the end
    end

    def extract_title_from_url(url)
      # Extract a rough title from URL slug
      uri = URI.parse(url)
      path = uri.path

      # Get the last segment
      slug = path.split("/").last
      return "Article" if slug.blank?

      # Convert slug to title
      slug
        .gsub(/[-_]/, " ")
        .gsub(/\.html?$/i, "")
        .split
        .map(&:capitalize)
        .join(" ")
    rescue
      "Article"
    end

    def extract_site_url
      uri = URI.parse(@feed_url)
      "#{uri.scheme}://#{uri.host}"
    rescue
      nil
    end
  end
end
