class ScrapeGithubTrendingJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(language: "ruby", time_range: "daily")
    Rails.logger.info "Starting GitHub trending scrape for #{language} (#{time_range})"

    result = ImportTrendingRepos.call(
      language: language,
      time_range: time_range,
      cleanup_old_data: true,
      days_to_keep: 30
    )

    if result.success?
      Rails.logger.info <<~LOG
        GitHub trending scrape completed successfully:
        - Imported: #{result.imported_count} repos
        - Skipped: #{result.skipped_count} duplicates#{'  '}
        - Failed: #{result.failed_count} repos
      LOG

      # Optionally trigger a webhook or notification
      notify_on_success(result) if defined?(notify_on_success)
    else
      Rails.logger.error "GitHub trending scrape failed: #{result.error}"

      # Optionally send error notification
      notify_on_failure(result) if defined?(notify_on_failure)

      raise result.error
    end
  end

  private

  def notify_on_success(result)
    # Future: Add webhook or Slack notification
  end

  def notify_on_failure(result)
    # Future: Add error alerting
  end
end
