class Entry < ApplicationRecord
  searchkick text_middle: [:title, :summary, :content, :author],
             word_start: [:title, :author],
             highlight: [:title, :summary],
             searchable: [:title, :summary, :content, :author, :tags],
             filterable: [:entry_type, :published_at, :feed_id]
  
  belongs_to :feed

  validates :title, presence: true
  validates :url, presence: true
  validates :guid, uniqueness: true, allow_nil: true
  validates :entry_type, presence: true

  enum :entry_type, {
    article: "article",
    podcast: "podcast",
    video: "video"
  }

  scope :published, -> { where.not(published_at: nil) }
  scope :recent, -> { order(published_at: :desc) }
  scope :processed, -> { where(processed: true) }
  scope :unprocessed, -> { where(processed: false) }
  scope :articles, -> { where(entry_type: "article") }
  scope :podcasts, -> { where(entry_type: "podcast") }
  scope :videos, -> { where(entry_type: "video") }

  before_save :extract_basic_tags, :detect_entry_type

  def tag_list
    return [] if tags.blank?
    JSON.parse(tags)
  rescue JSON::ParserError
    []
  end

  def tag_list=(new_tags)
    self.tags = new_tags.to_json
  end

  def content_preview(length = 300)
    return summary if summary.present?
    return "" if content.blank?

    clean_content = ActionController::Base.helpers.strip_tags(content)
    clean_content.truncate(length)
  end

  def podcast?
    entry_type == "podcast"
  end

  def article?
    entry_type == "article"
  end

  def video?
    entry_type == "video"
  end

  def formatted_duration
    return nil unless duration && (podcast? || video?)

    hours = duration / 3600
    minutes = (duration % 3600) / 60
    seconds = duration % 60

    if hours > 0
      "#{hours}:#{minutes.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}"
    else
      "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
    end
  end

  def search_data
    {
      title: title,
      summary: summary,
      content: ActionController::Base.helpers.strip_tags(content || ""),
      author: author,
      tags: tag_list,
      entry_type: entry_type,
      published_at: published_at,
      feed_id: feed_id,
      feed_name: feed.name,
      feed_category: feed.category
    }
  end

  private

  def extract_basic_tags
    return if title.blank?

    # Simple tag extraction from title
    ruby_tags = []
    ruby_tags << "ruby" if title.match?(/ruby/i)
    ruby_tags << "rails" if title.match?(/rails/i)
    ruby_tags << "testing" if title.match?(/test|rspec|spec/i)
    ruby_tags << "performance" if title.match?(/performance|speed|optimization/i)
    ruby_tags << "deployment" if title.match?(/deploy|docker|kubernetes/i)
    ruby_tags << "podcast" if feed.podcast? || entry_type == "podcast"
    ruby_tags << "video" if entry_type == "video"

    self.tag_list = ruby_tags if ruby_tags.any?
  end

  def detect_entry_type
    # Auto-detect entry type if not set
    return if entry_type.present?

    if feed.podcast?
      self.entry_type = "podcast"
    elsif url&.match?(/youtube|vimeo|video/i)
      self.entry_type = "video"
    else
      self.entry_type = "article"
    end
  end
end
