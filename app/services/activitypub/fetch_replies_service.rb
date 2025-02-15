# frozen_string_literal: true

class ActivityPub::FetchRepliesService < BaseService
  include JsonLdHelper

  def call(parent_status, collection_or_uri, allow_synchronous_requests: true, request_id: nil)
    @account = parent_status.account
    @allow_synchronous_requests = allow_synchronous_requests

    @items = collection_items(collection_or_uri)
    return if @items.nil?

    filter_replies!

    FetchReplyWorker.perform_bulk(@items.map { |item| [item, { 'request_id' => request_id }] })

    @items
  end

  private

  def collection_items(collection_or_uri)
    collection = fetch_collection(collection_or_uri)
    return unless collection.is_a?(Hash)

    collection = fetch_collection(collection['first']) if collection['first'].present?
    return unless collection.is_a?(Hash)

    case collection['type']
    when 'Collection', 'CollectionPage'
      collection['items']
    when 'OrderedCollection', 'OrderedCollectionPage'
      collection['orderedItems']
    end
  end

  def fetch_collection(collection_or_uri)
    return collection_or_uri if collection_or_uri.is_a?(Hash)
    return unless @allow_synchronous_requests
    return if invalid_origin?(collection_or_uri)
    fetch_resource_without_id_validation(collection_or_uri, nil, true)
  end

  def filter_replies!
    # Only fetch replies to the same server as the original status to avoid
    # amplification attacks.

    # Vanilla Mastodon only fetches the first 5 items. We relax the limit to 8.
    @items.map! { |item| value_or_id(item) }
    @items.reject! { |uri| invalid_origin?(uri) }
    @items = @items.take(8)
  end
end
