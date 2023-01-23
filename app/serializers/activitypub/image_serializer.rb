# frozen_string_literal: true

class ActivityPub::ImageSerializer < ActivityPub::Serializer
  include RoutingHelper

  context_extension :focal_point

  serialize(:type) { 'Image' }

  serialize :url
  serialize :mediaType, from: :content_type

  show_if :focal_point? do
    serialize :focalPoint, from: :focal_point
  end

  def url
    full_asset_url(model.url(:original))
  end

  def focal_point?
    model.respond_to?(:meta) && model.meta.is_a?(Hash) && model.meta['focus'].is_a?(Hash)
  end

  def focal_point
    [model.meta['focus']['x'], model.meta['focus']['y']]
  end
end
