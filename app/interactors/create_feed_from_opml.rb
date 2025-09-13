class CreateFeedFromOpml
  include Interactor

  def call
    validate_feed_data!
    
    # Check if feed already exists
    existing_feed = Feed.find_by(feed_url: context.feed_data[:feed_url])
    
    if existing_feed
      context.feed = existing_feed
      context.skipped = true
      context.message = "Feed already exists: #{existing_feed.name}"
      return
    end
    
    # Create new feed
    feed = Feed.new(
      name: context.feed_data[:name],
      url: context.feed_data[:url],
      feed_url: context.feed_data[:feed_url],
      description: context.feed_data[:description],
      category: context.feed_data[:category],
      active: true,
      fetch_interval: determine_fetch_interval
    )
    
    if feed.save
      context.feed = feed
      context.created = true
      context.message = "Successfully created feed: #{feed.name}"
    else
      context.fail!(
        error: "Failed to create feed: #{feed.errors.full_messages.join(', ')}",
        feed_data: context.feed_data
      )
    end
  end

  private

  def validate_feed_data!
    unless context.feed_data.is_a?(Hash)
      context.fail!(error: "Invalid feed data format")
    end
    
    unless context.feed_data[:feed_url].present?
      context.fail!(error: "Feed URL is required")
    end
    
    unless context.feed_data[:name].present?
      context.fail!(error: "Feed name is required")
    end
  end

  def determine_fetch_interval
    # Different fetch intervals based on category
    case context.feed_data[:category]
    when 'newsletter'
      86400  # Daily for newsletters
    when 'podcast'
      43200  # Twice daily for podcasts
    when 'company'
      7200   # Every 2 hours for company blogs
    else
      3600   # Hourly for personal/community blogs
    end
  end
end