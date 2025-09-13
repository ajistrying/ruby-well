# Feed Management Rake Tasks

This document describes all available rake tasks for managing RSS/Atom feeds and entries.

## Quick Start

```bash
# Complete setup: Import OPML and fetch all feeds
rake feeds:setup

# Import feeds from OPML
rake feeds:import_opml

# Fetch all feeds
rake feeds:fetch_all

# Show statistics
rake feeds:stats
```

## Import Tasks

### `feeds:import_opml[source]`
Import feeds from an OPML file (URL or local path).

```bash
# Import from default URL (awesome-ruby-blogs)
rake feeds:import_opml

# Import from custom URL
rake feeds:import_opml["https://example.com/feeds.opml"]

# Import from local file
rake feeds:import_opml["/path/to/feeds.opml"]
```

### `feeds:export_opml[filename]`
Export current feeds to OPML format.

```bash
# Export with auto-generated filename
rake feeds:export_opml

# Export to specific file
rake feeds:export_opml["my_feeds.opml"]
```

## Fetching Tasks

### `feeds:fetch_all`
Fetch entries for all active feeds (respects fetch intervals).

```bash
rake feeds:fetch_all
```

### `feeds:force_fetch_all`
Force fetch all feeds, ignoring last fetch time.

```bash
rake feeds:force_fetch_all
```

### `feeds:fetch_category[category]`
Fetch entries for feeds in a specific category.

```bash
rake feeds:fetch_category[podcast]
rake feeds:fetch_category[newsletter]
rake feeds:fetch_category[company]
rake feeds:fetch_category[community]
rake feeds:fetch_category[personal]
```

### `feeds:fetch_single[identifier]`
Fetch entries for a single feed by name or ID.

```bash
# By name
rake feeds:fetch_single["Boring Rails"]

# By ID
rake feeds:fetch_single[123]
```

### `feeds:fetch_stale`
Fetch only feeds that haven't been updated recently (based on their fetch intervals).

```bash
rake feeds:fetch_stale
```

## Management Tasks

### `feeds:stats`
Display comprehensive feed and entry statistics.

```bash
rake feeds:stats
```

Output includes:
- Total feeds (active/inactive)
- Breakdown by category
- Entry counts by type
- Recent activity

### `feeds:errors`
List all feeds with fetch errors.

```bash
rake feeds:errors
```

### `feeds:reset_failed`
Reset failed feeds (clear errors and reactivate). Interactive confirmation required.

```bash
rake feeds:reset_failed
```

### `feeds:clean_duplicates`
Remove duplicate entries based on GUID.

```bash
rake feeds:clean_duplicates
```

## Testing Tasks

### `feeds:test_parser[url]`
Test the feed parser with a specific URL without saving entries.

```bash
rake feeds:test_parser["https://example.com/feed.xml"]
```

### `feeds:setup[opml_source]`
Complete setup: Import OPML and fetch all feeds.

```bash
# Default setup
rake feeds:setup

# Custom OPML source
rake feeds:setup["https://example.com/feeds.opml"]
```

## Background Jobs

Most fetching tasks use Sidekiq background jobs for scalable processing:

- `FetchAllFeedsJob` - Orchestrates fetching all feeds
- `FetchSingleFeedJob` - Fetches a single feed

## Feed Categories

The system supports these feed categories:

- **personal** - Individual developer blogs
- **company** - Company engineering blogs  
- **community** - Community blogs and resources
- **newsletter** - Email newsletters
- **podcast** - Podcast feeds

## Error Handling

- Feeds with 5+ consecutive failures are automatically deactivated
- Use `feeds:errors` to see problematic feeds
- Use `feeds:reset_failed` to reactivate failed feeds

## Scheduling

For production use, schedule these tasks with cron or whenever:

```ruby
# config/whenever.rb
every 1.hour do
  rake "feeds:fetch_stale"
end

every 1.day do
  rake "feeds:clean_duplicates"
end
```

## Examples

```bash
# Daily workflow
rake feeds:fetch_stale          # Fetch feeds that need updating
rake feeds:stats                # Check results
rake feeds:errors               # Check for any problems

# Weekly maintenance
rake feeds:clean_duplicates     # Remove duplicates
rake feeds:reset_failed         # Reset failed feeds

# Adding new feeds
rake feeds:import_opml["new_feeds.opml"]
rake feeds:fetch_all

# Troubleshooting
rake feeds:test_parser["https://problematic-feed.com/rss"]
rake feeds:fetch_single["Problem Feed Name"]
```