namespace :feeds do
  desc "Import feeds from OPML file (URL or local path)"
  task :import_opml, [ :source ] => :environment do |t, args|
    source = args[:source] || "https://raw.githubusercontent.com/Yegorov/awesome-ruby-blogs/master/opml/all.opml"

    puts "Importing OPML from: #{source}"
    puts "=" * 60

    result = ImportOpmlFeeds.call(opml_source: source)

    if result.success?
      puts result.import_report
    else
      puts "Import failed: #{result.error}"
      exit 1
    end
  end

  desc "Fetch entries for all active feeds"
  task fetch_all: :environment do
    puts "Fetching entries for all active feeds..."

    FetchAllFeedsJob.perform_now

    puts "Feed fetching jobs queued successfully"
  end

  desc "Fetch entries for feeds by category (personal, company, newsletter, podcast, community)"
  task :fetch_category, [ :category ] => :environment do |t, args|
    unless args[:category]
      puts "Please specify a category: rake feeds:fetch_category[podcast]"
      exit 1
    end

    category = args[:category]
    count = Feed.active.where(category: category).count

    puts "Fetching entries for #{count} #{category} feeds..."

    FetchAllFeedsJob.perform_now(category: category)

    puts "Feed fetching jobs queued for #{category} feeds"
  end

  desc "Fetch entries for a single feed by name or ID"
  task :fetch_single, [ :identifier ] => :environment do |t, args|
    unless args[:identifier]
      puts "Please specify a feed name or ID: rake feeds:fetch_single['Boring Rails']"
      exit 1
    end

    # Try to find by ID first, then by name
    feed = Feed.find_by(id: args[:identifier]) || Feed.find_by(name: args[:identifier])

    unless feed
      puts "Feed not found: #{args[:identifier]}"
      exit 1
    end

    puts "Fetching entries for: #{feed.name}"
    puts "URL: #{feed.feed_url}"
    puts "-" * 40

    result = FetchFeedEntries.call(feed: feed)

    if result.success? && result.stats
      puts "✓ Success!"
      puts "  Created: #{result.stats[:created]} entries"
      puts "  Skipped: #{result.stats[:skipped]} entries"
      puts "  Failed: #{result.stats[:failed]} entries"
    else
      puts "✗ Failed: #{result.error}"
      exit 1
    end
  end

  desc "Force fetch all feeds (ignores last fetch time)"
  task force_fetch_all: :environment do
    puts "Force fetching all active feeds..."

    FetchAllFeedsJob.perform_now(force: true)

    puts "Force fetch jobs queued successfully"
  end

  desc "Show feed statistics"
  task stats: :environment do
    puts "\nFeed Statistics"
    puts "=" * 50

    puts "\nOverall:"
    puts "  Total feeds: #{Feed.count}"
    puts "  Active feeds: #{Feed.active.count}"
    puts "  Inactive feeds: #{Feed.where(active: false).count}"
    puts "  Failed feeds (5+ failures): #{Feed.where('fetch_failures >= ?', 5).count}"

    puts "\nBy Category:"
    Feed.group(:category).count.each do |category, count|
      active = Feed.active.where(category: category).count
      puts "  #{category.capitalize}: #{count} total, #{active} active"
    end

    puts "\nEntries:"
    puts "  Total entries: #{Entry.count}"
    puts "  Articles: #{Entry.articles.count}"
    puts "  Podcasts: #{Entry.podcasts.count}"
    puts "  Videos: #{Entry.videos.count}"

    puts "\nRecent Activity:"
    recent = Feed.where("last_fetched_at > ?", 1.hour.ago).count
    puts "  Feeds fetched in last hour: #{recent}"

    if Feed.any?
      last_fetch = Feed.maximum(:last_fetched_at)
      puts "  Last fetch: #{last_fetch&.strftime('%Y-%m-%d %H:%M:%S UTC')}"
    end
  end

  desc "List feeds with errors"
  task errors: :environment do
    failed_feeds = Feed.where("fetch_failures > 0").order(fetch_failures: :desc)

    if failed_feeds.any?
      puts "\nFeeds with Errors"
      puts "=" * 50

      failed_feeds.each do |feed|
        puts "\n#{feed.name} (ID: #{feed.id})"
        puts "  Category: #{feed.category}"
        puts "  URL: #{feed.feed_url}"
        puts "  Failures: #{feed.fetch_failures}"
        puts "  Last error: #{feed.error_message}"
        puts "  Status: #{feed.active? ? 'Active' : 'Inactive'}"
      end

      puts "\nTotal: #{failed_feeds.count} feeds with errors"
    else
      puts "No feeds with errors!"
    end
  end

  desc "Reset failed feeds (clear errors and reactivate)"
  task reset_failed: :environment do
    failed_feeds = Feed.where("fetch_failures > 0")
    count = failed_feeds.count

    if count > 0
      print "Reset #{count} failed feeds? (y/n): "
      answer = STDIN.gets.chomp.downcase

      if answer == "y"
        failed_feeds.update_all(
          fetch_failures: 0,
          error_message: nil,
          active: true
        )
        puts "✓ Reset #{count} feeds"
      else
        puts "Cancelled"
      end
    else
      puts "No failed feeds to reset"
    end
  end

  desc "Clean duplicate entries"
  task clean_duplicates: :environment do
    puts "Checking for duplicate entries..."

    duplicates = Entry
      .select("guid, feed_id, COUNT(*) as count")
      .where.not(guid: nil)
      .group(:guid, :feed_id)
      .having("COUNT(*) > 1")

    total_duplicates = 0

    duplicates.each do |dup|
      entries = Entry.where(guid: dup.guid, feed_id: dup.feed_id).order(:created_at)
      # Keep the first, delete the rest
      entries.offset(1).destroy_all
      total_duplicates += (dup.count - 1)
    end

    if total_duplicates > 0
      puts "✓ Removed #{total_duplicates} duplicate entries"
    else
      puts "No duplicate entries found"
    end
  end

  desc "Test feed parser with a specific URL"
  task :test_parser, [ :url ] => :environment do |t, args|
    unless args[:url]
      puts "Please specify a feed URL: rake feeds:test_parser['https://example.com/feed.xml']"
      exit 1
    end

    puts "Testing parser for: #{args[:url]}"
    puts "-" * 40

    begin
      parser = FeedParsers::SmartParser.new(args[:url])
      result = parser.parse

      puts "✓ Successfully parsed!"
      puts "  Title: #{result[:title]}"
      puts "  Description: #{result[:description]}" if result[:description]
      puts "  Entries found: #{result[:entries].size}"

      if result[:entries].any?
        puts "\nFirst entry:"
        entry = result[:entries].first
        puts "  Title: #{entry[:title]}"
        puts "  URL: #{entry[:url]}"
        puts "  Published: #{entry[:published_at]}"
      end
    rescue => e
      puts "✗ Parser failed: #{e.message}"
      exit 1
    end
  end

  desc "Full setup: Import OPML and fetch all feeds"
  task :setup, [ :opml_source ] => :environment do |t, args|
    source = args[:opml_source] || "https://raw.githubusercontent.com/Yegorov/awesome-ruby-blogs/master/opml/all.opml"

    puts "Starting full feed setup..."
    puts "=" * 60

    # Import OPML
    Rake::Task["feeds:import_opml"].invoke(source)

    puts "\nWaiting 5 seconds before fetching entries..."
    sleep 5

    # Fetch all feeds
    Rake::Task["feeds:fetch_all"].invoke

    puts "\n" + "=" * 60
    puts "Setup complete! Use 'rake feeds:stats' to see results"
  end

  desc "Fetch stale feeds (not updated recently)"
  task fetch_stale: :environment do
    stale_feeds = Feed.ready_for_fetch
    count = stale_feeds.count

    puts "Found #{count} stale feeds to update..."

    if count > 0
      stale_feeds.find_each do |feed|
        FetchSingleFeedJob.perform_later(feed.id)
      end

      puts "✓ Queued #{count} stale feeds for fetching"
    else
      puts "No stale feeds found"
    end
  end

  desc "Export feeds to OPML file"
  task :export_opml, [ :filename ] => :environment do |t, args|
    filename = args[:filename] || "feeds_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.opml"

    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.opml(version: "2.0") do
        xml.head do
          xml.title "Ruby Feed Export"
          xml.dateCreated Time.current.rfc822
        end

        xml.body do
          Feed.group_by(&:category).each do |category, feeds|
            xml.outline(text: category.capitalize, title: category.capitalize) do
              feeds.each do |feed|
                xml.outline(
                  type: "rss",
                  text: feed.name,
                  title: feed.name,
                  xmlUrl: feed.feed_url,
                  htmlUrl: feed.url || feed.feed_url
                )
              end
            end
          end
        end
      end
    end

    File.write(filename, builder.to_xml)
    puts "✓ Exported #{Feed.count} feeds to #{filename}"
  end
end
