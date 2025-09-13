require 'nokogiri'
require 'open-uri'

class ParseOpmlFile
  include Interactor

  def call
    context.fail!(error: "No OPML source provided") unless context.opml_source.present?
    
    begin
      opml_content = fetch_opml_content
      context.feeds_data = parse_opml(opml_content)
      context.total_feeds = context.feeds_data.size
    rescue StandardError => e
      context.fail!(error: "Failed to parse OPML: #{e.message}")
    end
  end

  private

  def fetch_opml_content
    source = context.opml_source
    
    if source.start_with?('http://', 'https://')
      URI.open(source).read
    elsif File.exist?(source)
      File.read(source)
    else
      raise ArgumentError, "Invalid OPML source: #{source}"
    end
  end

  def parse_opml(content)
    doc = Nokogiri::XML(content)
    feeds = []
    
    # Find all outline elements with xmlUrl (these are the actual feeds)
    doc.xpath('//outline[@xmlUrl]').each do |outline|
      feed_data = extract_feed_data(outline)
      feeds << feed_data if feed_data[:feed_url].present?
    end
    
    feeds
  end

  def extract_feed_data(outline)
    # Get the parent outline for category information
    parent = outline.parent
    category = determine_category(parent, outline)
    
    {
      name: outline['title'] || outline['text'] || 'Unnamed Feed',
      feed_url: outline['xmlUrl'],
      url: outline['htmlUrl'],
      description: outline['description'],
      category: category
    }
  end

  def determine_category(parent, outline)
    # Check parent's text/title for category hints
    parent_text = (parent['text'] || parent['title'] || '').downcase if parent.name == 'outline'
    feed_title = (outline['title'] || outline['text'] || '').downcase
    
    # Map OPML categories to our Feed model categories
    if parent_text
      case parent_text
      when /community/i
        'community'
      when /company|corporate/i
        'company'
      when /newsletter/i
        'newsletter'
      when /podcast/i
        'podcast'
      else
        'personal'
      end
    elsif feed_title.include?('podcast')
      'podcast'
    elsif feed_title.include?('newsletter')
      'newsletter'
    else
      'personal'
    end
  end
end