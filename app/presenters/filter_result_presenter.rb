# frozen_string_literal: true

class FilterResultPresenter
  attr_reader :filter, :keyword_matches, :status_matches

  def initialize(filter:, keyword_matches:, status_matches:)
    @filter = filter
    @keyword_matches = keyword_matches
    @status_matches = status_matches
  end
end
