class ImportTrendingRepos
  include Interactor

  def call
    scraper = GithubTrendingScraper.new(
      language: context.language || "ruby",
      time_range: context.time_range || "daily"
    )

    result = scraper.scrape

    unless result[:success]
      context.fail!(error: result[:error])
      return
    end

    imported = []
    failed = []
    skipped = []

    result[:repos].each do |repo_data|
      begin
        repo = TrendingRepo.import_from_scraper(repo_data)
        imported << repo
        Rails.logger.info "Imported trending repo: #{repo.full_name}"
      rescue ActiveRecord::RecordInvalid => e
        if e.message.include?("has already been taken")
          skipped << repo_data[:full_name]
          Rails.logger.info "Skipped duplicate repo: #{repo_data[:full_name]}"
        else
          failed << { repo: repo_data[:full_name], error: e.message }
          Rails.logger.error "Failed to import repo #{repo_data[:full_name]}: #{e.message}"
        end
      rescue StandardError => e
        failed << { repo: repo_data[:full_name], error: e.message }
        Rails.logger.error "Failed to import repo #{repo_data[:full_name]}: #{e.message}"
      end
    end

    # Clean up old data (keep last 30 days by default)
    if context.cleanup_old_data != false
      deleted_count = TrendingRepo.cleanup_old_data(context.days_to_keep || 30)
      Rails.logger.info "Cleaned up #{deleted_count} old trending repos"
    end

    context.imported_count = imported.length
    context.failed_count = failed.length
    context.skipped_count = skipped.length
    context.imported = imported
    context.failed = failed
    context.skipped = skipped

    log_summary
  end

  private

  def log_summary
    Rails.logger.info <<~LOG
      GitHub Trending Import Summary:
      - Imported: #{context.imported_count} repos
      - Skipped: #{context.skipped_count} duplicates
      - Failed: #{context.failed_count} repos
      - Date: #{Date.current}
    LOG
  end
end
