# Load sidekiq-cron schedule from sidekiq.yml
if Rails.env.production? || Rails.env.development?
  require "sidekiq"
  require "sidekiq-cron"

  # Load the schedule from config/sidekiq.yml
  schedule_file = Rails.root.join("config", "sidekiq.yml")

  if File.exist?(schedule_file) && Sidekiq.server?
    config = YAML.load_file(schedule_file)

    if config[:schedule]
      Rails.logger.info "Loading Sidekiq-Cron schedule..."

      Sidekiq::Cron::Job.load_from_hash(config[:schedule])

      Rails.logger.info "Loaded #{config[:schedule].keys.count} scheduled jobs:"
      config[:schedule].keys.each do |job_name|
        Rails.logger.info "  - #{job_name}"
      end
    end
  end
end
