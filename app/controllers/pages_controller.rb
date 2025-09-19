class PagesController < ApplicationController
  def home
    @total_entries = Entry.count
    @total_feeds = Feed.active.count
    @recent_entries = Entry.recent.includes(:feed).limit(5)
    @categories = Feed.group(:category).count
    @entry_types = Entry.group(:entry_type).count

    # Fetch trending repos for today
    @trending_repos = TrendingRepo.today.top(5)
  end
end
