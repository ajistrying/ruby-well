class Feed < ApplicationRecord
  has_many :entries, dependent: :destroy

  validates :name, presence: true
  validates :feed_url, presence: true, uniqueness: true
  validates :category, presence: true

  enum :category, {
    personal: "personal",
    company: "company",
    community: "community",
    newsletter: "newsletter",
    podcast: "podcast"
  }

  scope :active, -> { where(active: true) }
  scope :stale, -> { where("last_fetched_at < ? OR last_fetched_at IS NULL", 1.hour.ago) }
  scope :ready_for_fetch, -> { active.stale.where("fetch_failures < ?", 5) }

  def should_fetch?
    return false unless active?
    return true if last_fetched_at.nil?
    return false if fetch_failures >= 5

    last_fetched_at < fetch_interval.seconds.ago
  end

  def mark_fetch_success
    update!(
      last_fetched_at: Time.current,
      last_successful_fetch_at: Time.current,
      fetch_failures: 0,
      error_message: nil
    )
  end

  def mark_fetch_failure(error)
    update!(
      last_fetched_at: Time.current,
      fetch_failures: fetch_failures + 1,
      error_message: error.message
    )
  end

  def recent_entries(limit = 10)
    entries.order(published_at: :desc).limit(limit)
  end
end
