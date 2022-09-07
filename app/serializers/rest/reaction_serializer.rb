# frozen_string_literal: true

class REST::ReactionSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  field :name

  field :count do |object|
    object.respond_to?(:count) ? object.count : 0
  end

  field :url, if: -> (_name, object, options) {
    object.custom_emoji.present?
  } do |object|
    full_asset_url(object.custom_emoji.image.url)
  end

  field :static_url, if: -> (_name, object, options) {
    object.custom_emoji.present?
  } do |object|
    full_asset_url(object.custom_emoji.image.url(:static))
  end

  view :guest do
  end

  view :logged_in do
    field :me
  end
end
