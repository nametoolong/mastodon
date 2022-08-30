# frozen_string_literal: true

class REST::StatusSerializer < Blueprinter::Base
  extend FormattingHelper
  extend StaticRoutingHelper

  fields :created_at, :spoiler_text, :language, :replies_count,
         :reblogs_count, :favourites_count, :edited_at

  field :id do |object|
    object.id.to_s
  end

  field :in_reply_to_id do |object|
    object.in_reply_to_id&.to_s
  end

  field :in_reply_to_account_id do |object|
    object.in_reply_to_account_id&.to_s
  end

  field :visibility do |object|
    # This visibility is masked behind "private"
    # to avoid API changes because there are no
    # UX differences
    if object.limited_visibility?
      'private'
    else
      object.visibility
    end
  end

  field :uri do |object|
    ActivityPub::TagManager.instance.uri_for(object)
  end

  field :url do |object|
    ActivityPub::TagManager.instance.url_for(object)
  end

  field :content, if: -> (_name, object, options) {
    !options[:source_requested]
  } do |object|
    status_content_format(object)
  end

  field :text, if: -> (_name, object, options) {
    options[:source_requested]
  }

  field :mentions do |object|
    object.active_mentions.to_a.sort_by(&:id).map do |mention|
      {
        id: mention.account_id.to_s,
        username: mention.account_username,
        url: ActivityPub::TagManager.instance.url_for(mention.account),
        acct: mention.account.pretty_acct
      }
    end
  end

  field :tags do |object|
    object.tags.map do |tag|
      {name: tag.name, url: tag_url(tag)}
    end
  end

  association :account, blueprint: REST::AccountSerializer
  association :emojis, blueprint: REST::CustomEmojiSerializer
  association :preview_card, name: :card, blueprint: REST::PreviewCardSerializer
  association :ordered_media_attachments, name: :media_attachments, blueprint: REST::MediaAttachmentSerializer

  view :guest do
    field :sensitive do |object|
      object.account.sensitized? || object.sensitive
    end

    field :application, if: -> (_name, object, options) {
      object.account.user_shows_application?
    } do |object|
      object.application && {name: object.application.name, website: object.application.website.presence}
    end

    association :reblog, blueprint: REST::StatusSerializer, view: :guest
    association :preloadable_poll, name: :poll, blueprint: REST::PollSerializer, view: :guest
  end

  view :logged_in do
    field :sensitive do |object, options|
      if options[:current_account].id == object.account_id
        object.sensitive
      else
        object.account.sensitized? || object.sensitive
      end
    end

    field :application, if: -> (_name, object, options) {
      object.account.user_shows_application? || options[:current_account].id == object.account_id
    } do |object|
      object.application && {name: object.application.name, website: object.application.website.presence}
    end

    field :favourited do |object, options|
      if options[:relationships]
        options[:relationships].favourites_map[object.id] || false
      else
        options[:current_account].favourited?(object)
      end
    end

    field :reblogged do |object, options|
      if options[:relationships]
        options[:relationships].reblogs_map[object.id] || false
      else
        options[:current_account].reblogged?(object)
      end
    end

    field :muted do |object, options|
      if options[:relationships]
        options[:relationships].mutes_map[object.conversation_id] || false
      else
        options[:current_account].muting_conversation?(object.conversation)
      end
    end

    field :bookmarked do |object, options|
      if options[:relationships]
        options[:relationships].bookmarks_map[object.id] || false
      else
        options[:current_account].bookmarked?(object)
      end
    end

    field :pinned, if: -> (_name, object, options) {
        options[:current_account].id == object.account_id &&
        !object.reblog? &&
        %w(public unlisted private).include?(object.visibility)
    } do |object, options|
      if options[:relationships]
        options[:relationships].pins_map[object.id] || false
      else
        options[:current_account].pinned?(object)
      end
    end

    field :filtered do |object, options|
      if options[:relationships]
        filtered = options[:relationships].filters_map[object.id] || []
      else
        filtered = options[:current_account].status_matches_filters(object)
      end

      ActiveModel::Serializer::CollectionSerializer.new(
        filtered,
        serializer: REST::FilterResultSerializer
      ).as_json
    end

    association :reblog, blueprint: REST::StatusSerializer, view: :logged_in
    association :preloadable_poll, name: :poll, blueprint: REST::PollSerializer, view: :logged_in
  end
end
