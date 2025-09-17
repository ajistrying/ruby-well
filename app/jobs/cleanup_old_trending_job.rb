class CleanupOldTrendingJob < ApplicationJob
  queue_as :low

  def perform(days_to_keep: 30)
    Rails.logger.info "Starting cleanup of old trending repository data..."

    deleted_count = TrendingRepo.cleanup_old_data(days_to_keep)

    Rails.logger.info "Cleanup completed: Removed #{deleted_count} records older than #{days_to_keep} days"
  end
end
