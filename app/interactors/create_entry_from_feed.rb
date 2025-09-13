class CreateEntryFromFeed
  include Interactor

  def call
    validate_inputs!

    # Check for duplicate entry
    if duplicate_entry_exists?
      context.skipped = true
      context.message = "Entry already exists: #{context.entry_data[:title]}"
      return
    end

    # Create new entry
    entry = context.feed.entries.build(
      title: context.entry_data[:title],
      url: context.entry_data[:url],
      guid: context.entry_data[:guid],
      summary: context.entry_data[:summary],
      content: context.entry_data[:content],
      published_at: context.entry_data[:published_at] || Time.current,
      author: context.entry_data[:author],
      enclosure_url: context.entry_data[:enclosure_url],
      duration: context.entry_data[:duration],
      entry_type: determine_entry_type,
      processed: false
    )

    if entry.save
      context.entry = entry
      context.created = true
      context.message = "Created entry: #{entry.title}"
    else
      context.fail!(
        error: "Failed to create entry: #{entry.errors.full_messages.join(', ')}",
        entry_data: context.entry_data
      )
    end
  end

  private

  def validate_inputs!
    unless context.feed.present?
      context.fail!(error: "Feed is required")
    end

    unless context.entry_data.present?
      context.fail!(error: "Entry data is required")
    end

    unless context.entry_data[:title].present? && context.entry_data[:url].present?
      context.fail!(error: "Entry must have title and URL")
    end
  end

  def duplicate_entry_exists?
    # Check by GUID first (most reliable)
    if context.entry_data[:guid].present?
      return context.feed.entries.exists?(guid: context.entry_data[:guid])
    end

    # Fallback to URL + published_at combination
    if context.entry_data[:url].present?
      existing = context.feed.entries.where(url: context.entry_data[:url])

      if context.entry_data[:published_at].present?
        # Check for same URL and published date (within 1 hour tolerance)
        published_at = context.entry_data[:published_at]
        existing = existing.where(
          published_at: (published_at - 1.hour)..(published_at + 1.hour)
        )
      end

      return existing.exists?
    end

    false
  end

  def determine_entry_type
    # Check if feed is a podcast
    if context.feed.podcast?
      return "podcast"
    end

    # Check for podcast indicators in entry
    if context.entry_data[:enclosure_url].present? || context.entry_data[:duration].present?
      return "podcast"
    end

    # Check for video indicators
    if context.entry_data[:url]&.match?(/youtube|vimeo|video/i)
      return "video"
    end

    # Default to article
    "article"
  end
end
