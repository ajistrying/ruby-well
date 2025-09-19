require "nokogiri"
require "faraday"

class GithubTrendingScraper
  BASE_URL = "https://github.com/trending"

  def initialize(language: "ruby", time_range: "daily")
    @language = language
    @time_range = time_range
  end

  def scrape
    response = fetch_page
    return { success: false, error: "Failed to fetch page", repos: [] } unless response.success?

    doc = Nokogiri::HTML(response.body)
    repos = parse_repos(doc)

    { success: true, repos: repos }
  rescue StandardError => e
    Rails.logger.error "GitHub scraping failed: #{e.message}"
    { success: false, error: e.message, repos: [] }
  end

  private

  def fetch_page
    url = "#{BASE_URL}/#{@language}?since=#{@time_range}"

    Faraday.get(url) do |req|
      req.headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
      req.headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      req.headers["Accept-Language"] = "en-US,en;q=0.5"
      req.options.timeout = 10
      req.options.open_timeout = 5
    end
  end

  def parse_repos(doc)
    repo_elements = doc.css("article.Box-row")

    repo_elements.map.with_index do |element, index|
      parse_single_repo(element, index + 1)
    end.compact
  end

  def parse_single_repo(element, position)
    # Extract repository info
    repo_link = element.css("h2 a").first
    return nil unless repo_link

    full_name = repo_link["href"].sub(%r{^/}, "")
    owner, name = full_name.split("/")

    # Extract description
    description_element = element.css("p.col-9").first
    description = description_element&.text&.strip

    # Extract stars today
    stars_today_element = element.css("span.d-inline-block.float-sm-right").first
    stars_today = extract_stars_today(stars_today_element)

    # Extract total stars and forks
    stats = element.css("a.Link--muted.d-inline-block.mr-3")
    total_stars = extract_stat_value(stats[0])
    forks = extract_stat_value(stats[1])

    # Extract contributors
    contributors = extract_contributors(element)

    # Extract language (already filtered by Ruby, but we'll confirm)
    language_element = element.css('span[itemprop="programmingLanguage"]').first
    language = language_element&.text&.strip || @language.capitalize

    {
      github_id: full_name.downcase.gsub("/", "-"),
      name: name,
      owner: owner,
      full_name: full_name,
      description: description,
      url: "https://github.com/#{full_name}",
      stars_today: stars_today,
      total_stars: total_stars,
      forks: forks,
      language: language,
      position: position,
      contributors: contributors,
      trending_date: Date.current
    }
  rescue StandardError => e
    Rails.logger.error "Failed to parse repo at position #{position}: #{e.message}"
    nil
  end

  def extract_stars_today(element)
    return 0 unless element

    text = element.text.strip
    # Extract number from text like "15 stars today"
    match = text.match(/(\d+(?:,\d+)*)\s+stars?\s+today/i)
    return 0 unless match

    match[1].gsub(",", "").to_i
  end

  def extract_stat_value(element)
    return 0 unless element

    text = element.text.strip
    # Remove commas and convert to integer
    text.gsub(",", "").to_i
  end

  def extract_contributors(element)
    # Extract contributor avatar URLs
    contributor_elements = element.css('a[href*="/graphs/contributors"] img')

    contributor_elements.map do |img|
      {
        avatar_url: img["src"],
        username: img["alt"]&.sub("@", "")
      }
    end
  end
end
