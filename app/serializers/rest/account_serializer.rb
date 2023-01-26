# frozen_string_literal: true

class REST::AccountSerializer < Blueprinter::Base
  extend FormattingHelper
  extend StaticRoutingHelper

  fields :username, :group, :followers_count, :following_count, :statuses_count

  field :id do |object|
    object.id.to_s
  end

  field :pretty_acct, name: :acct

  field :display_name do |object|
    object.suspended? ? '' : object.display_name
  end

  field :locked do |object|
    object.suspended? ? false : object.locked
  end

  field :bot do |object|
    object.suspended? ? false : object.bot
  end

  field :discoverable do |object|
    object.suspended? ? false : object.discoverable
  end

  field :note do |object|
    object.suspended? ? '' : account_bio_format(object)
  end

  field :created_at do |object|
    object.created_at.midnight.as_json
  end

  field :last_status_at do |object|
    object.last_status_at&.to_date&.iso8601
  end

  field :url do |object|
    ActivityPub::TagManager.instance.url_for(object)
  end

  field :avatar do |object|
    full_asset_url(object.suspended? ? object.avatar.default_url : object.avatar_original_url)
  end

  field :avatar_static do |object|
    full_asset_url(object.suspended? ? object.avatar.default_url : object.avatar_static_url)
  end

  field :header do |object|
    full_asset_url(object.suspended? ? object.header.default_url : object.header_original_url)
  end

  field :header_static do |object|
    full_asset_url(object.suspended? ? object.header.default_url : object.header_static_url)
  end

  field :suspended, if: ->(_name, object, options) {
    object.suspended?
  } do |object|
    object.suspended?
  end

  field :limited, if: ->(_name, object, options) {
    object.silenced?
  } do |object|
    object.silenced?
  end

  field :noindex, if: ->(_name, object, options) {
    object.local?
  } do |object, options|
    if options[:settings]
      options[:settings][:noindex]
    else
      object.user_prefers_noindex?
    end
  end

  field :fields do |object|
    if object.suspended?
      []
    else
      object.fields.map do |field|
        {
          "name": field.name,
          "value": account_field_value_format(field),
          "verified_at": field.verified_at&.iso8601
        }
      end
    end
  end

  association :emojis, blueprint: REST::CustomEmojiSerializer

  association :moved, blueprint: REST::AccountSerializer, if: ->(_name, object, options) {
    object.moved?
  } do |object|
    object.suspended? ? nil : AccountDecorator.new(object.moved_to_account)
  end

  association :roles, blueprint: REST::RoleSerializer, view: :public, if: ->(_name, object, options) {
    object.local?
  } do |object|
    if object.suspended?
      []
    else
      [object.user.role].tap(&:compact!).keep_if(&:highlighted?)
    end
  end

  class AccountDecorator < SimpleDelegator
    def self.model_name
      Account.model_name
    end

    def moved?
      false
    end
  end
end
