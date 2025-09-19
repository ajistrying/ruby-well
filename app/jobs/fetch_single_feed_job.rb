class FetchSingleFeedJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(feed_id)
    feed = Feed.find(feed_id)

    # Skip if feed is inactive or recently fetched
    return unless feed.should_fetch?

    Rails.logger.info "Fetching entries for feed: #{feed.name}"

    result = FetchFeedEntries.call(feed: feed)

    if result.success? && result.stats.present?
      Rails.logger.info "Fetched #{result.stats[:created]} new entries for #{feed.name}"
    else
      Rails.logger.error "Failed to fetch entries for #{feed.name}: #{result.error}"
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Feed not found: #{feed_id}"
  end
end
