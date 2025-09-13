class FetchFeedEntries
  include Interactor::Organizer

  organize ParseFeedContent, ProcessFeedEntries, UpdateFeedStatus

  around do |interactor|
    # Initialize context
    context.success = false

    begin
      interactor.call
    rescue => e
      # Catch any unhandled errors
      context.error = e.message
      context.success = false

      # Still update feed status even on failure
      UpdateFeedStatus.call(context)
    end
  end
end
