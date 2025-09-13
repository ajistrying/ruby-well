# RubyWell 💎

**A comprehensive Ruby content aggregator that brings together the best of the Ruby community in one searchable place.**

RubyWell aims to be the definitive source for discovering Ruby and Rails content from across the web. By aggregating blogs, podcasts, newsletters, and community resources, we create a centralized hub where developers can find exactly what they're looking for in the Ruby ecosystem.

## 🎯 Mission

The Ruby community produces incredible content every day - from in-depth technical blogs and engineering insights to educational podcasts and community newsletters. But this content is scattered across hundreds of individual sites, making it hard to discover and stay current with.

RubyWell solves this by:

- **Aggregating** content from 400+ Ruby blogs, podcasts, and newsletters
- **Organizing** everything by source type (personal blogs, company engineering blogs, podcasts, newsletters)  
- **Providing** intelligent search and filtering to find exactly what you need
- **Staying current** with automatic feed monitoring and content updates

## ✨ What's Inside

### 🌊 Content Sources

- **Personal Blogs** (288 sources) - Individual Ruby developers sharing their insights
- **Company Blogs** (76 sources) - Engineering teams from Ruby-powered companies
- **Community Resources** (38 sources) - Ruby community sites and collaborative blogs
- **Newsletters** (14 sources) - Curated Ruby content delivered regularly
- **Podcasts** (5 sources) - Audio content from Ruby thought leaders

### 📡 Smart Aggregation

RubyWell uses intelligent parsing to handle the diverse landscape of web feeds:

- **RSS/Atom Feeds** - Standard blog feeds and podcast feeds
- **JSON Feeds** - Modern JSON-based content syndication
- **WordPress APIs** - Direct integration with WordPress sites
- **Sitemap Parsing** - Fallback for sites without traditional feeds

### 🔍 Content Discovery

*(Coming Soon)*
- **Full-text search** across all aggregated content
- **Tag-based filtering** for topics like Rails, testing, deployment
- **Category browsing** by content type and source
- **Trending content** based on community engagement
- **Personalized recommendations** based on reading history

## 🛠️ Technology Stack

### Backend Architecture
- **Rails 8** - Modern Rails with the latest features
- **Interactor Pattern** - Clean business logic organization
- **Sidekiq** - Background job processing for feed fetching
- **Feedjira** - Robust RSS/Atom feed parsing
- **Faraday** - HTTP client with retry logic and timeouts

### Data Management
- **SQLite** - Simple, reliable database for development
- **Smart Deduplication** - Prevents duplicate content across sources
- **Feed Health Monitoring** - Automatic error tracking and recovery
- **Content Sanitization** - Clean, consistent content formatting

### Operational Tools
- **Comprehensive Rake Tasks** - Easy feed management and monitoring
- **OPML Import/Export** - Standard feed list format support
- **Background Processing** - Scalable content fetching
- **Health Monitoring** - Feed status tracking and error reporting

## 🚀 Getting Started

### Prerequisites
- Ruby 3.3+
- Rails 8.0+
- Redis (for Sidekiq)
- Node.js (for asset compilation)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/ruby-well.git
cd ruby-well

# Install dependencies
bundle install
npm install

# Setup database
rails db:create
rails db:migrate

# Import feeds and start aggregating content
rake feeds:setup

# Start the application
rails server

# Start background job processing
bundle exec sidekiq
```

### Feed Management

```bash
# Check aggregation status
rake feeds:stats

# Fetch latest content
rake feeds:fetch_all

# Add new feeds from OPML
rake feeds:import_opml[path/to/feeds.opml]

# Monitor for issues
rake feeds:errors
```

## 📊 Current Stats

- **421 Active Feeds** across all categories
- **Intelligent Parsing** handles 92% of feeds automatically
- **Background Processing** for scalable content fetching
- **Duplicate Prevention** ensures clean, unique content
- **Error Recovery** with automatic retry and fallback strategies

## 🔧 Architecture

RubyWell is built with a clean, modular architecture:

- **Interactors** handle business logic (OPML import, feed parsing, entry creation)
- **Service Objects** provide specialized parsing for different feed formats
- **Background Jobs** manage scalable, respectful content fetching
- **Models** maintain data integrity with proper validation and relationships

For detailed architecture documentation, see [CLAUDE.md](CLAUDE.md).

## 📚 Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete system architecture and component documentation
- **[FEED_TASKS.md](FEED_TASKS.md)** - Comprehensive rake task reference
- **Architecture Overview** - How all the pieces fit together
- **Deployment Guide** - Production setup and monitoring

## 🤝 Contributing

RubyWell is an open-source project aimed at serving the Ruby community. We welcome contributions of all kinds:

- **Feed Sources** - Know a great Ruby blog we're missing? Submit a PR!
- **Feature Requests** - Ideas for better content discovery and organization
- **Bug Reports** - Help us improve reliability and performance
- **Code Contributions** - Parser improvements, UI enhancements, new features

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Ruby Community** - For producing amazing content worth aggregating
- **Feed Authors** - All the developers sharing their knowledge
- **Open Source Tools** - Feedjira, Sidekiq, Rails, and all the gems that make this possible
- **OPML Sources** - Thanks to projects like [awesome-ruby-blogs](https://github.com/Yegorov/awesome-ruby-blogs) for curated feed lists

---

**Built with ❤️ for the Ruby community**

*RubyWell: Where Ruby knowledge flows together*