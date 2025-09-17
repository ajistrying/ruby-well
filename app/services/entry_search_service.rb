class EntrySearchService
  attr_reader :query, :filters, :page

  def initialize(params = {})
    @query = params[:query].to_s.strip
    @page = params[:page] || 1
    @filters = build_filters(params)
  end

  def search
    if query.present?
      perform_text_search
    else
      browse_entries
    end
  end

  def suggestions
    return [] unless query.present? && query.length >= 2

    Entry.search(
      query,
      fields: [ :title ],
      match: :word_start,
      limit: 5,
      load: false,
      misspellings: { below: 3 }
    ).map(&:title)
  end

  def facets
    @facets ||= calculate_facets
  end

  private

  def build_filters(params)
    filters = {}
    filters[:entry_type] = params[:entry_type] if params[:entry_type].present?
    filters[:feed_category] = params[:feed_category] if params[:feed_category].present?
    filters[:date_range] = parse_date_range(params[:date_from], params[:date_to])
    filters.compact
  end

  def parse_date_range(from, to)
    return nil if from.blank? && to.blank?

    {
      from: from.present? ? Date.parse(from) : 1.year.ago.to_date,
      to: to.present? ? Date.parse(to) : Date.current
    }
  rescue ArgumentError
    nil
  end

  def perform_text_search
    where_conditions = build_where_conditions

    Entry.search(
      query,
      where: where_conditions,
      fields: search_fields,
      highlight: highlight_options,
      page: page,
      per_page: 20,
      order: { _score: :desc, published_at: :desc },
      misspellings: { below: 5 },
      operator: "or",
      boost_where: boost_conditions,
      includes: [ :feed ]
    )
  end

  def browse_entries
    scope = Entry.includes(:feed).recent
    scope = apply_filters(scope)
    scope.page(page).per(20)
  end

  def build_where_conditions
    conditions = {}

    if filters[:entry_type].present?
      conditions[:entry_type] = filters[:entry_type]
    end

    if filters[:feed_category].present?
      feed_ids = Feed.where(category: filters[:feed_category]).pluck(:id)
      conditions[:feed_id] = feed_ids
    end

    if filters[:date_range].present?
      conditions[:published_at] = {
        gte: filters[:date_range][:from],
        lte: filters[:date_range][:to]
      }
    end

    conditions
  end

  def apply_filters(scope)
    if filters[:entry_type].present?
      scope = scope.where(entry_type: filters[:entry_type])
    end

    if filters[:feed_category].present?
      scope = scope.joins(:feed).where(feeds: { category: filters[:feed_category] })
    end

    if filters[:date_range].present?
      scope = scope.where(
        published_at: filters[:date_range][:from]..filters[:date_range][:to]
      )
    end

    scope
  end

  def search_fields
    [ "title^5", "author^3", "summary^2", "content", "tags" ]
  end

  def highlight_options
    {
      tag: "<mark class='bg-yellow-200'>",
      fields: {
        title: { fragment_size: 100 },
        summary: { fragment_size: 200 },
        content: { fragment_size: 150 }
      }
    }
  end

  def boost_conditions
    {
      entry_type: { value: "article", factor: 1.2 },
      published_at: { value: { gte: 30.days.ago }, factor: 1.5 }
    }
  end

  def calculate_facets
    {
      entry_types: Entry.group(:entry_type).count,
      feed_categories: Feed.joins(:entries).group(:category).count,
      recent_months: recent_months_facet
    }
  end

  def recent_months_facet
    Entry.where(published_at: 6.months.ago..)
      .count
  end
end
