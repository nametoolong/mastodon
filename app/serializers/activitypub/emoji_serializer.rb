# frozen_string_literal: true

class ActivityPub::EmojiSerializer < ActivityPub::Serializer
  include RoutingHelper

  context_extension :emoji

  serialize(:type) { 'Emoji' }

  serialize :id, :name, :updated

  serialize :icon, from: :image, with: ActivityPub::ImageSerializer

  def id
    ActivityPub::TagManager.instance.uri_for(model)
  end

  def name
    ":#{model.shortcode}:"
  end

  def updated
    model.updated_at.iso8601
  end
end
