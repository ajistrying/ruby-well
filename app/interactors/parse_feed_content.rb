class ParseFeedContent
  include Interactor

  def call
    validate_inputs!

    parser = FeedParsers::SmartParser.new(context.feed.feed_url, context.feed)
    result = parser.parse

    context.parsed_feed = result
    context.entries_data = result[:entries] || []
    context.feed_metadata = {
      title: result[:title],
      description: result[:description],
      url: result[:url],
      last_modified: result[:last_modified],
      etag: result[:etag]
    }

    Rails.logger.info "Successfully parsed #{context.entries_data.size} entries from #{context.feed.name}"
  rescue => e
    Rails.logger.error "Failed to parse feed #{context.feed.name}: #{e.message}"
    context.fail!(error: e.message)
  end

  private

  def validate_inputs!
    unless context.feed.present?
      context.fail!(error: "Feed is required")
    end

    unless context.feed.feed_url.present?
      context.fail!(error: "Feed URL is required")
    end
  end
end
