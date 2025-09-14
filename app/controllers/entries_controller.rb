class EntriesController < ApplicationController
  def index
    @search_service = EntrySearchService.new(params)
    @entries = @search_service.search
    @facets = @search_service.facets

    respond_to do |format|
      format.html
      format.turbo_stream if params[:turbo_frame].present?
    end
  end

  def show
    @entry = Entry.find(params[:id])
    @related_entries = find_related_entries(@entry)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def find_related_entries(entry)
    return [] unless entry.tags.present?

    Entry.search(
      entry.tag_list.join(" "),
      where: { id: { not: entry.id } },
      limit: 5,
      order: { published_at: :desc }
    )
  rescue
    Entry.where.not(id: entry.id)
         .where(feed_id: entry.feed_id)
         .recent
         .limit(5)
  end
end
