# frozen_string_literal: true

class StatusRelationshipsPresenter
  attr_reader :reblogs_map, :favourites_map, :mutes_map, :pins_map,
              :bookmarks_map, :filters_map

  def initialize(statuses, current_account_id = nil, **options)
    if current_account_id.nil?
      @reblogs_map    = {}
      @favourites_map = {}
      @bookmarks_map  = {}
      @mutes_map      = {}
      @pins_map       = {}
      @filters_map    = {}
    else
      statuses            = statuses.compact
      status_ids          = (statuses.each_with_object({}) do |status, h|
        h[status.id] = true
        h[status.reblog_of_id] = true if status.reblog?
      end).keys
      conversation_ids    = (statuses.each_with_object({}) do |status, h|
        h[status.conversation_id] = true
      end).keys
      pinnable_status_ids = statuses.map(&:proper).filter_map { |s| s.id if s.account_id == current_account_id && %w(public unlisted private).include?(s.visibility) }

      @filters_map     = build_filters_map(statuses, current_account_id).merge(options[:filters_map] || {})
      @reblogs_map     = Status.reblogs_map(status_ids, current_account_id).merge(options[:reblogs_map] || {})
      @favourites_map  = Status.favourites_map(status_ids, current_account_id).merge(options[:favourites_map] || {})
      @bookmarks_map   = Status.bookmarks_map(status_ids, current_account_id).merge(options[:bookmarks_map] || {})
      @mutes_map       = Status.mutes_map(conversation_ids, current_account_id).merge(options[:mutes_map] || {})
      @pins_map        = Status.pins_map(pinnable_status_ids, current_account_id).merge(options[:pins_map] || {})
    end
  end

  private

  def build_filters_map(statuses, current_account_id)
    active_filters = CustomFilter.cached_filters_for(current_account_id)

    @filters_map = statuses.each_with_object({}) do |status, h|
      filter_matches = CustomFilter.apply_cached_filters(active_filters, status)

      unless filter_matches.empty?
        h[status.id] = filter_matches
        h[status.reblog_of_id] = filter_matches if status.reblog?
      end
    end
  end
end
