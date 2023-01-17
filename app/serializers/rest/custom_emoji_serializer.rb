# frozen_string_literal: true

class REST::CustomEmojiSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  fields :shortcode, :visible_in_picker

  field :url do |object|
    full_asset_url(object.image.url)
  end

  field :static_url do |object|
    full_asset_url(object.image.url(:static))
  end

  field :category, if: ->(_name, object, options) {
    object.association(:category).loaded? && object.category.present?
  } do |object|
    object.category.name
  end
end
