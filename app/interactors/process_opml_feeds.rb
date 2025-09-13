class ProcessOpmlFeeds
  include Interactor

  def call
    context.created_feeds = []
    context.skipped_feeds = []
    context.failed_feeds = []

    context.feeds_data.each do |feed_data|
      result = CreateFeedFromOpml.call(feed_data: feed_data)

      if result.success?
        if result.created
          context.created_feeds << result.feed
        elsif result.skipped
          context.skipped_feeds << {
            feed: result.feed,
            message: result.message
          }
        end
      else
        context.failed_feeds << {
          feed_data: feed_data,
          error: result.error
        }
      end
    end

    # Set summary statistics
    context.stats = {
      total: context.feeds_data.size,
      created: context.created_feeds.size,
      skipped: context.skipped_feeds.size,
      failed: context.failed_feeds.size
    }

    generate_import_report
  end

  private

  def generate_import_report
    report = []
    report << "=" * 60
    report << "OPML Import Complete"
    report << "=" * 60
    report << "Total feeds processed: #{context.stats[:total]}"
    report << "Successfully created: #{context.stats[:created]}"
    report << "Skipped (already exist): #{context.stats[:skipped]}"
    report << "Failed: #{context.stats[:failed]}"
    report << ""

    if context.created_feeds.any?
      report << "Created Feeds:"
      report << "-" * 40
      context.created_feeds.each do |feed|
        report << "✓ #{feed.name} (#{feed.category})"
        report << "  URL: #{feed.feed_url}"
      end
      report << ""
    end

    if context.skipped_feeds.any?
      report << "Skipped Feeds:"
      report << "-" * 40
      context.skipped_feeds.each do |item|
        report << "○ #{item[:feed].name} - #{item[:message]}"
      end
      report << ""
    end

    if context.failed_feeds.any?
      report << "Failed Feeds:"
      report << "-" * 40
      context.failed_feeds.each do |item|
        report << "✗ #{item[:feed_data][:name]}"
        report << "  Error: #{item[:error]}"
      end
      report << ""
    end

    context.import_report = report.join("\n")
  end
end
