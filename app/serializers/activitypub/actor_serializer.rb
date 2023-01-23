# frozen_string_literal: true

class ActivityPub::ActorSerializer < ActivityPub::Serializer
  include RoutingHelper
  include FormattingHelper

  context :security
  context_extension :manually_approves_followers, :featured, :also_known_as,
                    :moved_to, :property_value, :discoverable, :olm, :suspended,
                    :hashtag

  use_contexts_from ActivityPub::EmojiSerializer

  serialize :type do |model|
    if model.instance_actor?
      'Application'
    elsif model.bot?
      'Service'
    elsif model.group?
      'Group'
    else
      'Person'
    end
  end

  serialize :id, :inbox, :outbox, :name,
            :summary, :url, :discoverable, :published

  serialize :preferredUsername, from: :username
  serialize :manuallyApprovesFollowers, from: :manually_approves_followers

  serialize :publicKey, from: :itself, with: ActivityPub::PublicKeySerializer

  nest_in :endpoints do
    serialize :sharedInbox, from: :shared_inbox
  end

  show_if ->(model) { model.suspended? } do
    serialize :suspended, from: :suspended?
  end

  show_if ->(model) { !(model.instance_actor? || model.suspended?) } do
    serialize :following, :followers, :devices, :featured
    serialize :featuredTags, from: :featured_tags

    serialize :attachment, :tag

    show_if ->(model) { model.moved? } do
      serialize :movedTo, from: :moved_to
    end

    show_if ->(model) { !model.also_known_as.empty? } do
      serialize :alsoKnownAs, from: :also_known_as
    end

    show_if ->(model) { model.avatar? } do
      serialize :icon, from: :avatar, with: ActivityPub::ImageSerializer
    end

    show_if ->(model) { model.header? } do
      serialize :image, from: :header, with: ActivityPub::ImageSerializer
    end
  end

  def id
    model.instance_actor? ? instance_actor_url : account_url(model)
  end

  def following
    account_following_index_url(model)
  end

  def followers
    account_followers_url(model)
  end

  def inbox
    model.instance_actor? ? instance_actor_inbox_url : account_inbox_url(model)
  end

  def outbox
    model.instance_actor? ? instance_actor_outbox_url : account_outbox_url(model)
  end

  def shared_inbox
    inbox_url
  end

  def devices
    account_collection_url(model, :devices)
  end

  def featured
    account_collection_url(model, :featured)
  end

  def featured_tags
    account_collection_url(model, :tags)
  end

  def discoverable
    model.suspended? ? false : (model.discoverable || false)
  end

  def name
    model.suspended? ? '' : model.display_name
  end

  def summary
    model.suspended? ? '' : account_bio_format(model)
  end

  def url
    model.instance_actor? ? about_more_url(instance_actor: true) : short_account_url(model)
  end

  def published
    model.created_at.midnight.iso8601
  end

  def manually_approves_followers
    model.suspended? ? false : model.locked
  end

  def moved_to
    ActivityPub::TagManager.instance.uri_for(model.moved_to_account)
  end

  def attachment
    model.fields.map do |field|
      {
        type: 'PropertyValue',
        name: field.name,
        value: account_field_value_format(field)
      }
    end
  end

  def tag
    emojis = CacheCrispies::Collection.new(model.emojis, ActivityPub::EmojiSerializer).as_json

    tags = model.tags.map do |tag|
      {
         type: 'Hashtag',
         href: tag_url(tag),
         name: "##{tag.name}"
      }
    end

    [emojis + tags].tap(&:flatten!)
  end
end
