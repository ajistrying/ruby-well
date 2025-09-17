namespace :trending do
  desc "Fetch latest trending Ruby repos from GitHub"
  task fetch: :environment do
    puts "Fetching trending Ruby repositories..."

    result = ImportTrendingRepos.call(
      language: "ruby",
      time_range: ENV["TIME_RANGE"] || "daily"
    )

    if result.success?
      puts "Successfully imported trending repos:"
      puts "  - Imported: #{result.imported_count} repos"
      puts "  - Skipped: #{result.skipped_count} duplicates"
      puts "  - Failed: #{result.failed_count} repos"

      if result.imported_count > 0
        puts "\nImported repos:"
        result.imported.each do |repo|
          puts "  #{repo.position}. #{repo.full_name} (⭐ #{repo.total_stars}, +#{repo.stars_today} today)"
        end
      end
    else
      puts "Failed to fetch trending repos: #{result.error}"
      exit 1
    end
  end

  desc "Fetch trending repos in background job"
  task fetch_async: :environment do
    puts "Queuing background job to fetch trending repos..."
    ScrapeGithubTrendingJob.perform_later
    puts "Job queued successfully!"
  end

  desc "Show current trending repos"
  task show: :environment do
    repos = TrendingRepo.today.by_position

    if repos.any?
      puts "\nToday's Trending Ruby Repositories (#{Date.current}):"
      puts "=" * 60

      repos.each do |repo|
        puts "\n#{repo.position}. #{repo.full_name}"
        puts "   #{repo.description}" if repo.description.present?
        puts "   ⭐ #{repo.total_stars} stars (#{repo.stars_today > 0 ? "+#{repo.stars_today} today" : "no change today"})"
        puts "   🍴 #{repo.forks} forks"
        puts "   🔗 #{repo.github_url}"
      end
    else
      puts "No trending repos found for today. Run 'rails trending:fetch' to fetch latest."
    end
  end

  desc "Show trending stats"
  task stats: :environment do
    total_repos = TrendingRepo.count
    today_repos = TrendingRepo.today.count
    unique_repos = TrendingRepo.select(:github_id).distinct.count
    date_range = TrendingRepo.pluck(:trending_date).minmax

    puts "\nTrending Repository Statistics:"
    puts "=" * 40
    puts "Total records: #{total_repos}"
    puts "Today's trending: #{today_repos}"
    puts "Unique repositories: #{unique_repos}"
    puts "Date range: #{date_range.first} to #{date_range.last}" if date_range.first

    # Top repos by frequency
    top_repos = TrendingRepo
      .group(:github_id, :full_name)
      .count
      .sort_by { |_, count| -count }
      .first(5)

    if top_repos.any?
      puts "\nMost frequently trending:"
      top_repos.each do |(github_id, full_name), count|
        puts "  #{full_name}: #{count} times"
      end
    end
  end

  desc "Clean up old trending data (keeps last 30 days by default)"
  task cleanup: :environment do
    days_to_keep = ENV["DAYS"] ? ENV["DAYS"].to_i : 30

    puts "Cleaning up trending data older than #{days_to_keep} days..."
    deleted_count = TrendingRepo.cleanup_old_data(days_to_keep)
    puts "Deleted #{deleted_count} old records."
  end

  desc "Test scraper without saving to database"
  task test_scraper: :environment do
    puts "Testing GitHub trending scraper..."

    scraper = GithubTrendingScraper.new(
      language: ENV["LANGUAGE"] || "ruby",
      time_range: ENV["TIME_RANGE"] || "daily"
    )

    result = scraper.scrape

    if result[:success]
      puts "Scraper test successful!"
      puts "Found #{result[:repos].length} repositories:"

      result[:repos].each do |repo|
        puts "\n#{repo[:position]}. #{repo[:full_name]}"
        puts "   Description: #{repo[:description]}" if repo[:description]
        puts "   Stars: #{repo[:total_stars]} (+#{repo[:stars_today]} today)"
        puts "   Forks: #{repo[:forks]}"
        puts "   Contributors: #{repo[:contributors].length}"
      end
    else
      puts "Scraper test failed: #{result[:error]}"
    end
  end
end
