class UpdateFeedStatus
  include Interactor

  def call
    validate_inputs!

    if context.success
      handle_success
    else
      handle_failure
    end
  end

  private

  def validate_inputs!
    unless context.feed.present?
      context.fail!(error: "Feed is required")
    end
  end

  def handle_success
    updates = {
      last_fetched_at: Time.current,
      last_successful_fetch_at: Time.current,
      fetch_failures: 0,
      error_message: nil
    }

    # Update feed metadata if available
    if context.feed_metadata.present?
      updates[:description] = context.feed_metadata[:description] if context.feed_metadata[:description].present?

      # Update URL if it's missing and we got one from the feed
      if context.feed.url.blank? && context.feed_metadata[:url].present?
        updates[:url] = context.feed_metadata[:url]
      end
    end

    context.feed.update!(updates)

    log_success_metrics
  end

  def handle_failure
    context.feed.update!(
      last_fetched_at: Time.current,
      fetch_failures: context.feed.fetch_failures + 1,
      error_message: context.error || "Unknown error"
    )

    # Deactivate feed after too many failures
    if context.feed.fetch_failures >= 5
      context.feed.update!(active: false)
      Rails.logger.warn "Feed #{context.feed.name} deactivated after 5 consecutive failures"
    end

    log_failure_metrics
  end

  def log_success_metrics
    if context.stats.present?
      Rails.logger.info [
        "Feed fetch successful for #{context.feed.name}:",
        "Created: #{context.stats[:created]}",
        "Skipped: #{context.stats[:skipped]}",
        "Failed: #{context.stats[:failed]}",
        "Total processed: #{context.stats[:total]}"
      ].join(" ")
    end
  end

  def log_failure_metrics
    Rails.logger.error [
      "Feed fetch failed for #{context.feed.name}:",
      "Error: #{context.error}",
      "Failure count: #{context.feed.fetch_failures}"
    ].join(" ")
  end
end
