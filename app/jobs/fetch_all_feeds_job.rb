class FetchAllFeedsJob < ApplicationJob
  queue_as :feeds

  def perform(options = {})
    # Options for controlling the fetch
    batch_size = options[:batch_size] || 10
    category = options[:category] # Optional: fetch only specific category
    force = options[:force] || false # Force fetch even if recently fetched

    feeds = Feed.active
    feeds = feeds.where(category: category) if category.present?
    feeds = force ? feeds : feeds.ready_for_fetch

    total_feeds = feeds.count
    Rails.logger.info "Starting fetch for #{total_feeds} feeds"

    # Process feeds in batches to avoid overwhelming the system
    feeds.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |feed|
        # Queue individual feed fetch jobs with slight delay to be respectful
        FetchSingleFeedJob.set(wait: rand(1..5).seconds).perform_later(feed.id)
      end

      # Add delay between batches
      sleep(2) unless Rails.env.test?
    end

    Rails.logger.info "Queued fetch jobs for #{total_feeds} feeds"
  end
end
