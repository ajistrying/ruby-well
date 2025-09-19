class TrendingRepo < ApplicationRecord
  validates :github_id, presence: true
  validates :name, presence: true
  validates :owner, presence: true
  validates :full_name, presence: true
  validates :url, presence: true
  validates :trending_date, presence: true
  validates :github_id, uniqueness: { scope: :trending_date }

  scope :for_date, ->(date) { where(trending_date: date) }
  scope :today, -> { for_date(Date.current) }
  scope :recent, -> { where(trending_date: 7.days.ago..Date.current) }
  scope :by_position, -> { order(:position) }
  scope :top, ->(limit = 5) { by_position.limit(limit) }

  def self.latest_trending_date
    maximum(:trending_date) || Date.current
  end

  def stars_display
    return "#{total_stars}" if stars_today.nil? || stars_today.zero?
    "#{total_stars} (+#{stars_today} today)"
  end

  def github_url
    url
  end

  def contributor_avatars
    contributors || []
  end

  def trending_position
    return nil unless position
    "##{position}"
  end

  def self.import_from_scraper(repo_data)
    repo = find_or_initialize_by(
      github_id: repo_data[:github_id],
      trending_date: repo_data[:trending_date] || Date.current
    )

    repo.update!(
      name: repo_data[:name],
      owner: repo_data[:owner],
      full_name: repo_data[:full_name],
      description: repo_data[:description],
      url: repo_data[:url],
      stars_today: repo_data[:stars_today] || 0,
      total_stars: repo_data[:total_stars] || 0,
      forks: repo_data[:forks] || 0,
      language: repo_data[:language] || "Ruby",
      position: repo_data[:position],
      contributors: repo_data[:contributors] || []
    )

    repo
  end

  def self.cleanup_old_data(days_to_keep = 30)
    where("trending_date < ?", days_to_keep.days.ago).destroy_all
  end
end
