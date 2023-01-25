# frozen_string_literal: true

class ActivityPub::NoteSerializer < ActivityPub::Serializer
  include FormattingHelper
  include RoutingHelper

  context_extension :atom_uri, :conversation, :hashtag, :sensitive, :voters_count

  use_contexts_from ActivityPub::EmojiSerializer

  class MediaAttachmentSerializer < ActivityPub::Serializer
    include RoutingHelper

    context_extension :blurhash, :focal_point

    serialize(:type) { 'Document' }

    serialize :url, :blurhash, :width, :height
    serialize :name, from: :description
    serialize :mediaType, from: :file_content_type

    show_if :focal_point? do
      serialize :focalPoint, from: :focal_point
    end

    show_if ->(model) { model.thumbnail.present? } do
      serialize :icon, from: :thumbnail, with: ActivityPub::ImageSerializer
    end

    def url
      model.local? ? full_asset_url(model.file.url(:original, false)) : model.remote_url
    end

    def focal_point?
      model.file.meta.is_a?(Hash) && model.file.meta['focus'].is_a?(Hash)
    end

    def focal_point
      [model.file.meta['focus']['x'], model.file.meta['focus']['y']]
    end

    def width
      model.file.meta&.dig('original', 'width')
    end

    def height
      model.file.meta&.dig('original', 'height')
    end
  end

  class OptionSerializer < ActivityPub::Serializer
    serialize(:type) { 'Note' }

    serialize :name, from: :title

    nest_in :replies do
      serialize(:type) { 'Collection' }

      serialize :totalItems, from: :votes_count
    end
  end

  serialize :type do |model|
    model.preloadable_poll ? 'Question' : 'Note'
  end

  serialize :id, :summary, :content, :published,
            :url, :to, :cc, :sensitive

  serialize :attributedTo, from: :attributed_to

  serialize :attachment, from: :ordered_media_attachments, with: MediaAttachmentSerializer

  serialize :tag

  show_if ->(model) { model.language.present? } do
    serialize :contentMap, from: :content_map
  end

  show_if ->(model) { model.edited? } do
    serialize :updated
  end

  show_if ->(model) { model.reply? && !model.thread.nil? } do
    serialize :inReplyTo, from: :in_reply_to
    serialize :inReplyToAtomUri, from: :in_reply_to_atom_uri
  end

  show_if ->(model) { model.account.local? } do
    serialize :atomUri, from: :atom_uri

    serialize :replies, with: ActivityPub::CollectionSerializer, collection: false
  end

  show_if ->(model) { model.conversation } do
    serialize :conversation
  end

  show_if ->(model) { !model.preloadable_poll.nil? } do
    show_if ->(model) { model.preloadable_poll.multiple? } do
      # Multiple options
      serialize :anyOf, from: :poll_options, with: OptionSerializer
    end

    show_if ->(model) { !model.preloadable_poll.multiple? } do
      # Single option
      serialize :oneOf, from: :poll_options, with: OptionSerializer
    end

    show_if ->(model) { model.preloadable_poll.expires_at.present? } do
      serialize :endTime, from: :end_time
    end

    show_if ->(model) { model.preloadable_poll.expired? } do
      serialize :closed, from: :end_time
    end

    show_if ->(model) { model.preloadable_poll.voters_count } do
      serialize :votersCount, from: :voters_count
    end
  end

  def id
    ActivityPub::TagManager.instance.uri_for(model)
  end

  def summary
    model.spoiler_text.presence
  end

  def content
    @content ||= status_content_format(model)
  end

  def content_map
    { model.language => content }
  end

  def in_reply_to
    if model.thread.uri.nil? || model.thread.uri.start_with?('http')
      ActivityPub::TagManager.instance.uri_for(model.thread)
    else
      model.thread.url
    end
  end

  def published
    model.created_at.iso8601
  end

  def updated
    model.edited_at.iso8601
  end

  def url
    ActivityPub::TagManager.instance.url_for(model)
  end

  def attributed_to
    ActivityPub::TagManager.instance.uri_for(model.account)
  end

  def to
    ActivityPub::TagManager.instance.to(model)
  end

  def cc
    ActivityPub::TagManager.instance.cc(model)
  end

  def sensitive
    model.account.sensitized? || model.sensitive
  end

  def tag
    mentions = model.active_mentions.to_a.sort_by!(&:id).map! do |mention|
      {
         type: 'Mention',
         href: ActivityPub::TagManager.instance.uri_for(mention.account),
         name: "@#{mention.account.acct}"
      }
    end

    tags = model.tags.map do |tag|
      {
         type: 'Hashtag',
         href: tag_url(tag),
         name: "##{tag.name}"
      }
    end

    emojis = CacheCrispies::Collection.new(model.emojis, ActivityPub::EmojiSerializer).as_json

    [mentions, tags, emojis].tap(&:flatten!)
  end

  def atom_uri
    OStatus::TagManager.instance.uri_for(model)
  end

  def in_reply_to_atom_uri
    OStatus::TagManager.instance.uri_for(model.thread)
  end

  def conversation
    if model.conversation.uri?
      model.conversation.uri
    else
      OStatus::TagManager.instance.unique_tag(model.conversation.created_at, model.conversation.id, 'Conversation')
    end
  end

  def replies
    replies = (
      (options[:replies_map] ? options[:replies_map][model.id] : nil) ||
      model.self_replies(5).pluck(:id, :uri)
    )

    next_page = begin
      last_id = replies.last&.first

      if last_id
        ActivityPub::TagManager.instance.replies_uri_for(model, page: true, min_id: last_id)
      else
        ActivityPub::TagManager.instance.replies_uri_for(model, page: true, only_other_accounts: true)
      end
    end

    replies_uri = ActivityPub::TagManager.instance.replies_uri_for(model)

    ActivityPub::CollectionPresenter.new(
      type: :unordered,
      id: replies_uri,
      first: ActivityPub::CollectionPresenter.new(
        type: :unordered,
        part_of: replies_uri,
        items: replies.map(&:second),
        next: next_page
      )
    )
  end

  def poll_options
    model.preloadable_poll.loaded_options
  end

  def end_time
    model.preloadable_poll.expires_at.iso8601
  end

  def voters_count
    model.preloadable_poll.voters_count
  end
end
