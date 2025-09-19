# Ruby-Well Community Resource Aggregator

A Rails 8 application for aggregating and managing RSS/Atom feeds from Ruby community blogs, podcasts, and newsletters, plus daily tracking of trending GitHub Ruby repositories. Built with intelligent parsing, web scraping, background processing, and comprehensive content management.

## 🏗️ Architecture Overview

This application follows a clean architecture pattern using interactors for business logic, background jobs for processing, and service objects for specialized parsing and scraping.

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Rake Tasks    │───▶│   Interactors   │───▶│   Models        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
                               ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Background Jobs │───▶│  Feed Parsers   │───▶│   Database      │
│  (Sidekiq)      │    │  & Scrapers     │    │   (SQLite)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                      │
        ▼                      ▼
┌─────────────────┐    ┌─────────────────┐
│  Sidekiq-Cron   │    │ GitHub Trending │
│  (Scheduled)    │    │   (Nokogiri)    │
└─────────────────┘    └─────────────────┘
```

## 📊 Data Models

### Feed Model (`app/models/feed.rb`)
Represents an RSS/Atom feed source.

**Key Attributes:**
- `name` - Display name of the feed
- `feed_url` - RSS/Atom feed URL
- `url` - Website homepage URL
- `category` - One of: personal, company, community, newsletter, podcast
- `active` - Whether feed is currently being fetched
- `fetch_interval` - Seconds between fetches (varies by category)
- `fetch_failures` - Count of consecutive failures
- `last_fetched_at` - Last attempt timestamp
- `last_successful_fetch_at` - Last successful fetch timestamp

**Key Methods:**
- `should_fetch?` - Determines if feed needs updating
- `mark_fetch_success/failure` - Updates fetch status
- `ready_for_fetch` scope - Feeds ready for updating

### Entry Model (`app/models/entry.rb`)
Represents individual blog posts, podcast episodes, or articles.

**Key Attributes:**
- `title` - Entry title
- `url` - Entry URL
- `guid` - Unique identifier from feed
- `summary` - Short description
- `content` - Full content (HTML)
- `published_at` - Publication date
- `author` - Author name
- `entry_type` - One of: article, podcast, video
- `duration` - Duration in seconds (for podcasts/videos)
- `enclosure_url` - Media file URL (for podcasts)
- `tags` - JSON array of tags
- `processed` - Whether entry has been AI-processed

**Key Methods:**
- `tag_list` - Parses JSON tags
- `content_preview` - Truncated clean content
- `formatted_duration` - Human-readable duration (MM:SS)

### TrendingRepo Model (`app/models/trending_repo.rb`)
Represents GitHub trending repositories scraped daily.

**Key Attributes:**
- `github_id` - Unique GitHub repository identifier
- `name` - Repository name
- `owner` - Repository owner/organization
- `full_name` - Full repository path (owner/name)
- `description` - Repository description
- `url` - GitHub repository URL
- `stars_today` - Stars gained today
- `total_stars` - Total star count
- `forks` - Fork count
- `language` - Primary programming language
- `trending_date` - Date when it was trending
- `position` - Position in trending list (1-25)
- `contributors` - JSON array of contributor data

**Key Methods:**
- `today` scope - Repos trending today
- `for_date(date)` scope - Repos for specific date
- `by_position` scope - Ordered by trending position
- `top(limit)` scope - Top N trending repos
- `import_from_scraper` - Creates/updates from scraped data
- `cleanup_old_data` - Removes old records
- `stars_display` - Formatted star count with daily gain
- `trending_position` - Formatted position (#1, #2, etc.)

## 🔧 Core Interactors

Interactors handle business logic using the [interactor gem](https://github.com/collectiveidea/interactor). Each interactor focuses on a single responsibility.

### OPML Import System

#### `ImportOpmlFeeds` (Organizer)
**File:** `app/interactors/import_opml_feeds.rb`
**Purpose:** Orchestrates OPML file import process
**Flow:** `ParseOpmlFile` → `ProcessOpmlFeeds`

#### `ParseOpmlFile`
**File:** `app/interactors/parse_opml_file.rb`
**Purpose:** Downloads and parses OPML XML files
**Input:** `opml_source` (URL or file path)
**Output:** `feeds_data` (array of parsed feed data)

**Features:**
- Supports remote URLs and local files
- Extracts feed metadata (name, URL, category)
- Maps OPML categories to internal categories
- Handles malformed OPML gracefully

#### `ProcessOpmlFeeds`
**File:** `app/interactors/process_opml_feeds.rb`
**Purpose:** Creates Feed records from parsed OPML data
**Input:** `feeds_data` from ParseOpmlFile
**Output:** Import statistics and detailed report

### Feed Entry Fetching System

#### `FetchFeedEntries` (Organizer)
**File:** `app/interactors/fetch_feed_entries.rb`
**Purpose:** Orchestrates fetching entries from a single feed
**Flow:** `ParseFeedContent` → `ProcessFeedEntries` → `UpdateFeedStatus`

#### `ParseFeedContent`
**File:** `app/interactors/parse_feed_content.rb`
**Purpose:** Downloads and parses feed content using smart parser
**Input:** `feed` (Feed model)
**Output:** `entries_data`, `feed_metadata`

**Features:**
- Uses `FeedParsers::SmartParser` for format detection
- Handles multiple feed formats automatically
- Extracts feed metadata for updating feed records

#### `ProcessFeedEntries`
**File:** `app/interactors/process_feed_entries.rb`
**Purpose:** Creates Entry records from parsed feed data
**Input:** `entries_data` from ParseFeedContent
**Output:** Created/skipped/failed entry statistics

**Features:**
- Duplicate detection using GUID and URL+date
- Batch processing of multiple entries
- Detailed statistics for monitoring

#### `CreateEntryFromFeed`
**File:** `app/interactors/create_entry_from_feed.rb`
**Purpose:** Creates individual Entry record with validation
**Input:** `feed`, `entry_data`
**Output:** Created Entry or skip/error status

**Features:**
- Duplicate checking by GUID or URL+date
- Automatic entry type detection (article/podcast/video)
- Content sanitization and validation

#### `UpdateFeedStatus`
**File:** `app/interactors/update_feed_status.rb`
**Purpose:** Updates feed metadata and fetch status
**Input:** `feed`, `success` flag, optional error
**Output:** Updated feed record

**Features:**
- Tracks fetch success/failure statistics
- Auto-deactivates feeds after 5 failures
- Updates feed metadata from parsed content
- Comprehensive logging

### Individual Feed Creation

#### `CreateFeedFromOpml`
**File:** `app/interactors/create_feed_from_opml.rb`
**Purpose:** Creates single Feed record from OPML data
**Input:** `feed_data` hash
**Output:** Created Feed record or skip/error status

**Features:**
- Duplicate detection by feed_url
- Category-based fetch interval assignment
- Input validation and error handling

### GitHub Trending System

#### `ImportTrendingRepos`
**File:** `app/interactors/import_trending_repos.rb`
**Purpose:** Imports trending Ruby repositories from GitHub
**Input:** `language` (default: "ruby"), `time_range` (default: "daily")
**Output:** Import statistics with imported/skipped/failed counts

**Features:**
- Calls GithubTrendingScraper service
- Handles deduplication and updates
- Automatic cleanup of old data (30+ days)
- Comprehensive error handling and logging
- Returns detailed import report

## 🔍 Feed Parser System

Located in `app/services/feed_parsers/`, this system provides intelligent parsing for multiple feed formats.

### `FeedParsers::SmartParser`
**File:** `app/services/feed_parsers/smart_parser.rb`
**Purpose:** Automatically detects and routes to appropriate parser

**Detection Logic:**
- WordPress JSON: URLs containing `wp-json/wp/v2`
- JSON Feed: URLs ending in `.json` or containing `/feed.json`
- Sitemap: URLs ending in `sitemap.xml`
- Default: RSS/Atom parser

**Fallback Strategy:**
If primary parser fails, tries all parsers in order of likelihood:
1. RSS/Atom (most common)
2. JSON Feed
3. WordPress JSON
4. Sitemap

### `FeedParsers::BaseParser`
**File:** `app/services/feed_parsers/base_parser.rb`
**Purpose:** Shared functionality for all parsers

**Features:**
- HTTP client with retry logic and timeouts
- Content sanitization (HTML cleaning)
- Date parsing with error handling
- GUID generation for feeds without unique IDs

### `FeedParsers::RssAtomParser`
**File:** `app/services/feed_parsers/rss_atom_parser.rb`
**Purpose:** Handles RSS 2.0 and Atom feeds using Feedjira

**Features:**
- Supports RSS 2.0, Atom 1.0, and iTunes podcast formats
- Extracts podcast-specific metadata (duration, enclosures)
- Handles various content field names across feed types
- Author extraction from multiple formats

### `FeedParsers::JsonFeedParser`
**File:** `app/services/feed_parsers/json_feed_parser.rb`
**Purpose:** Handles JSON Feed format (jsonfeed.org)

**Features:**
- Validates JSON Feed format version
- Extracts attachments for podcast/video content
- Handles both content_html and content_text
- Author and duration extraction

### `FeedParsers::WordpressJsonParser`
**File:** `app/services/feed_parsers/wordpress_json_parser.rb`
**Purpose:** Handles WordPress REST API endpoints

**Features:**
- Adds `_embed=1` parameter for rich content
- Extracts embedded author and media data
- Handles WordPress-specific content structure
- Fallback for missing metadata

### `FeedParsers::SitemapParser`
**File:** `app/services/feed_parsers/sitemap_parser.rb`
**Purpose:** Extracts recent posts from XML sitemaps

**Features:**
- Filters URLs that look like blog posts
- Sorts by lastmod date for recent content
- Generates titles from URL slugs
- Handles sitemap index files

## 🌟 GitHub Trending Scraper

### `GithubTrendingScraper`
**File:** `app/services/github_trending_scraper.rb`
**Purpose:** Scrapes trending Ruby repositories from GitHub

**Features:**
- HTML parsing using Nokogiri
- Extracts repository metadata (stars, forks, contributors)
- Handles daily/weekly/monthly trending periods
- Robust error handling with fallbacks
- User-Agent spoofing for reliable access

**Data Extracted:**
- Repository name, owner, and full path
- Description and primary language
- Total stars and stars gained today
- Fork count
- Contributor avatars
- Trending position (1-25)

**Usage:**
```ruby
scraper = GithubTrendingScraper.new(language: "ruby", time_range: "daily")
result = scraper.scrape
# Returns: { success: true/false, repos: [...], error: nil/message }
```

## ⚙️ Background Job System

Uses Sidekiq for reliable background processing with proper queuing and retry logic.

### `FetchAllFeedsJob`
**File:** `app/jobs/fetch_all_feeds_job.rb`
**Purpose:** Orchestrates fetching all feeds or specific categories

**Features:**
- Batch processing with configurable batch sizes
- Category filtering (e.g., only podcasts)
- Force mode to ignore fetch intervals
- Rate limiting to be respectful to servers
- Staggered job queuing to avoid overwhelming

### `FetchSingleFeedJob`
**File:** `app/jobs/fetch_single_feed_job.rb`
**Purpose:** Fetches entries for a single feed

**Features:**
- Exponential backoff retry strategy
- Respects feed's `should_fetch?` logic
- Comprehensive error logging
- Integration with feed failure tracking

### `ScrapeGithubTrendingJob`
**File:** `app/jobs/scrape_github_trending_job.rb`
**Purpose:** Fetches trending Ruby repositories from GitHub

**Features:**
- Scheduled daily via sidekiq-cron (2 AM)
- Calls ImportTrendingRepos interactor
- Automatic retry on failure with exponential backoff
- Detailed logging of import results
- Optional webhook/notification hooks

### `CleanupOldTrendingJob`
**File:** `app/jobs/cleanup_old_trending_job.rb`
**Purpose:** Removes old trending repository data

**Features:**
- Scheduled weekly via sidekiq-cron (Sundays at 3 AM)
- Configurable retention period (default: 30 days)
- Low priority queue to avoid interfering with fetching
- Logs cleanup statistics

## 🛠️ Rake Task System

### Feed Tasks
**File:** `lib/tasks/feeds.rake`

Comprehensive rake tasks for all feed operations:

### Import/Export Tasks
- `feeds:import_opml[source]` - Import from OPML
- `feeds:export_opml[filename]` - Export to OPML
- `feeds:setup[opml_source]` - Complete setup

### Fetching Tasks
- `feeds:fetch_all` - Fetch all active feeds
- `feeds:fetch_category[category]` - Fetch by category
- `feeds:fetch_single[identifier]` - Fetch single feed
- `feeds:fetch_stale` - Fetch only stale feeds
- `feeds:force_fetch_all` - Force fetch all

### Management Tasks
- `feeds:stats` - Show statistics
- `feeds:errors` - List problem feeds
- `feeds:reset_failed` - Reset failed feeds
- `feeds:clean_duplicates` - Remove duplicates

### Testing Tasks
- `feeds:test_parser[url]` - Test parser on URL

### GitHub Trending Tasks
**File:** `lib/tasks/trending.rake`

Tasks for managing GitHub trending repositories:

#### Fetching Tasks
- `trending:fetch` - Manually fetch latest trending repos
- `trending:fetch_async` - Queue background job for fetching
- `trending:test_scraper` - Test scraper without saving to database

#### Display Tasks
- `trending:show` - Display current trending repos in console
- `trending:stats` - Show statistics and most frequently trending

#### Maintenance Tasks
- `trending:cleanup` - Remove old trending data (configurable retention)

## 🔄 Data Flow

### OPML Import Flow
```
OPML URL/File → ParseOpmlFile → ProcessOpmlFeeds → Feed Records
```

### Feed Fetching Flow
```
Feed Record → ParseFeedContent → Smart Parser → Entry Data
                                      ↓
Feed Update ← UpdateFeedStatus ← ProcessFeedEntries ← Create Entries
```

### Background Processing Flow
```
Rake Task → FetchAllFeedsJob → Multiple FetchSingleFeedJob → FetchFeedEntries
```

### GitHub Trending Flow
```
Daily Cron → ScrapeGithubTrendingJob → ImportTrendingRepos → GithubTrendingScraper
                                              ↓
Database ← TrendingRepo.import_from_scraper ← Parsed HTML Data
```

## 🏷️ Feed Categories & Intervals

The system organizes feeds by category with different fetch intervals:

- **Newsletter** (86400s / daily) - Email newsletters
- **Podcast** (43200s / 12h) - Audio content  
- **Company** (7200s / 2h) - Company engineering blogs
- **Community** (3600s / 1h) - Community blogs and resources
- **Personal** (3600s / 1h) - Individual developer blogs

## 🔍 Error Handling & Monitoring

### Feed Health Tracking
- Each feed tracks consecutive failure count
- Feeds auto-deactivate after 5 failures
- Last error message stored for debugging
- Fetch timestamps for monitoring staleness

### Parser Resilience
- Multiple parser fallbacks
- Graceful handling of malformed feeds
- Detailed error logging with parser-specific messages
- Timeout protection for slow feeds

### Duplicate Prevention
- GUID-based deduplication (primary)
- URL + date fallback for feeds without GUIDs
- Clean duplicate removal via rake task

## 🖼️ User Interface Features

### Homepage
- **Recent Entries**: Latest blog posts, podcasts, and videos from RSS feeds
- **Trending Ruby Projects**: Top 5 trending GitHub repositories with:
  - Repository name and owner
  - Stars gained today indicator
  - Total stars and forks
  - Direct GitHub links

### Trending Repos Page (`/trending_repos`)
- Full list of 25 trending repositories
- Date selector for viewing historical data
- Detailed repository cards showing:
  - Trending position (#1-#25)
  - Full description
  - Stars gained today badge
  - Contributor avatars
  - Language and statistics
- Individual repo detail pages with trending history

### Navigation
- Main menu with links to Home, Browse (entries), and Trending
- Quick refresh button for manual updates
- Responsive design with DaisyUI components

## 🚀 Getting Started

### Initial Setup
```bash
# Import feeds and start fetching
rake feeds:setup

# Or step by step:
rake feeds:import_opml
rake feeds:fetch_all

# Fetch initial trending repos
rake trending:fetch
```

### Daily Operations
```bash
# Fetch stale feeds
rake feeds:fetch_stale

# Check feed status
rake feeds:stats

# View trending repos
rake trending:show

# Handle problems
rake feeds:errors
rake feeds:reset_failed
```

### GitHub Trending Operations
```bash
# Manual fetch of trending repos
rake trending:fetch

# Test scraper without saving
rake trending:test_scraper

# View trending statistics
rake trending:stats

# Clean up old data (> 30 days)
rake trending:cleanup
```

### Adding New Feeds
```bash
# Test a feed first
rake feeds:test_parser["https://example.com/feed.xml"]

# Import new OPML
rake feeds:import_opml["new_feeds.opml"]
```

## 📈 Monitoring & Maintenance

### Key Metrics to Watch
- Total active feeds vs. inactive
- Recent fetch activity (hourly/daily)
- Error rates by category
- Entry creation rates
- Failed feed count
- Daily trending repo imports
- Most frequently trending repositories
- GitHub scraper success rate

### Regular Maintenance
- Weekly duplicate cleanup
- Monthly failed feed review
- Periodic OPML export for backup
- Monitor disk space for entry content
- Automatic cleanup of trending data older than 30 days
- Monitor GitHub scraper for blocking or rate limiting

### Performance Considerations
- Background job queue monitoring
- Database index optimization for large entry sets
- Content trimming for very long articles
- Rate limiting respect for external servers

### Dependencies Added
- **Nokogiri**: HTML parsing for GitHub trending scraper
- **Sidekiq-Cron**: Already included, configured for scheduled jobs

### Scheduled Jobs Configuration
**File:** `config/schedule.yml`

Sidekiq-cron automatically loads jobs from this file:
- **scrape_github_trending**: Daily at 2 AM - Fetches trending repos
- **cleanup_old_trending**: Weekly on Sundays at 3 AM - Removes old data

This architecture provides a robust, scalable system for aggregating Ruby community content and tracking GitHub trending repositories while being respectful to external servers and handling various data formats gracefully.