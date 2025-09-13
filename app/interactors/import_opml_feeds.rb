class ImportOpmlFeeds
  include Interactor::Organizer

  organize ParseOpmlFile, ProcessOpmlFeeds
end
