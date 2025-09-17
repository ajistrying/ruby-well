class TrendingReposController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : TrendingRepo.latest_trending_date
    @trending_repos = TrendingRepo.for_date(@date).by_position

    # Get available dates for date selector
    @available_dates = TrendingRepo
      .select(:trending_date)
      .distinct
      .order(trending_date: :desc)
      .limit(30)
      .pluck(:trending_date)

    respond_to do |format|
      format.html
      format.json { render json: @trending_repos }
    end
  rescue Date::Error
    redirect_to trending_repos_path, alert: "Invalid date format"
  end

  def show
    @repo = TrendingRepo.find(params[:id])

    # Get historical data for this repo
    @history = TrendingRepo
      .where(github_id: @repo.github_id)
      .order(trending_date: :desc)
      .limit(30)
  end

  def refresh
    # Only allow refresh if user is authenticated (future feature)
    # For now, we'll allow it but rate limit

    last_import = TrendingRepo.maximum(:created_at)

    if last_import && last_import > 1.hour.ago
      redirect_to trending_repos_path, alert: "Trending data was recently updated. Please try again later."
      return
    end

    ScrapeGithubTrendingJob.perform_later
    redirect_to trending_repos_path, notice: "Refreshing trending repos. This may take a moment..."
  end
end
