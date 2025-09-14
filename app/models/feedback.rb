class Feedback < ApplicationRecord
  FEEDBACK_TYPES = %w[feature_request new_feed bug_report other].freeze

  validates :feedback_type, presence: true, inclusion: { in: FEEDBACK_TYPES }
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { maximum: 2000 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :feed_url, format: { with: URI::DEFAULT_PARSER.make_regexp }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(feedback_type: type) }
  scope :pending, -> { where(status: "pending") }
  scope :reviewed, -> { where(status: "reviewed") }

  def feature_request?
    feedback_type == "feature_request"
  end

  def new_feed?
    feedback_type == "new_feed"
  end

  def bug_report?
    feedback_type == "bug_report"
  end

  def type_label
    feedback_type.humanize.capitalize
  end

  def type_icon
    case feedback_type
    when "feature_request"
      "\u2728"
    when "new_feed"
      "\u{1F4E1}"
    when "bug_report"
      "\u{1F41B}"
    else
      "\u{1F4AC}"
    end
  end
end
