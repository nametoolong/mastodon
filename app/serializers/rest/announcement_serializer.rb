# frozen_string_literal: true

class REST::AnnouncementSerializer < Blueprinter::Base
  extend FormattingHelper
  extend StaticRoutingHelper

  fields :starts_at, :ends_at, :all_day,
         :published_at, :updated_at

  field :id do |object|
    object.id.to_s
  end

  field :content do |object|
    linkify(object.text)
  end

  field :mentions do |object|
    object.mentions.map do |account|
      {
        id: account.id.to_s,
        username: account.username,
        url: ActivityPub::TagManager.instance.url_for(account),
        acct: account.pretty_acct
      }
    end
  end

  field :statuses do |object|
    object.statuses.map do |status|
      {
        id: status.id.to_s,
        url: ActivityPub::TagManager.instance.url_for(status)
      }
    end
  end

  field :tags do |object|
    object.tags.map do |tag|
      {name: tag.name, url: tag_url(tag)}
    end
  end

  association :emojis, blueprint: REST::CustomEmojiSerializer

  view :guest do
  end

  view :logged_in do
    field :read do |object, options|
      object.announcement_mutes.where(account: options[:current_account]).exists?
    end

    association :reactions, blueprint: REST::ReactionSerializer, view: :logged_in do |object, options|
      object.reactions(options[:current_account])
    end
  end
end
