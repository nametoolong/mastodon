# frozen_string_literal: true

class REST::PreviewCardSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  fields :url, :title, :description, :type,
         :author_name, :author_url, :provider_name,
         :provider_url, :html, :width, :height,
         :embed_url, :blurhash

  field :image do |object|
    object.image? ? full_asset_url(object.image.url(:original)) : nil
  end
end
