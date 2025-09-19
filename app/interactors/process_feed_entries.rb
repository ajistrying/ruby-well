class ProcessFeedEntries
  include Interactor

  def call
    context.created_entries = []
    context.skipped_entries = []
    context.failed_entries = []

    context.entries_data.each do |entry_data|
      result = CreateEntryFromFeed.call(
        feed: context.feed,
        entry_data: entry_data
      )

      if result.success?
        if result.created
          context.created_entries << result.entry
        elsif result.skipped
          context.skipped_entries << {
            entry_data: entry_data,
            message: result.message
          }
          # Log skipped entries for monitoring
          Rails.logger.info "Entry skipped for feed '#{context.feed.name}': #{result.message}"
        end
      else
        context.failed_entries << {
          entry_data: entry_data,
          error: result.error
        }
        Rails.logger.warn "Failed to create entry for feed '#{context.feed.name}': #{result.error}"
      end
    end

    # Set statistics
    context.stats = {
      total: context.entries_data.size,
      created: context.created_entries.size,
      skipped: context.skipped_entries.size,
      failed: context.failed_entries.size
    }

    # Mark as successful even if some entries failed
    # (partial success is still success for feed fetching)
    context.success = true
  end
end
