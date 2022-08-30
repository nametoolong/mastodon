# frozen_string_literal: true

class REST::MediaAttachmentSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  fields :type, :description, :blurhash

  field :id do |object|
    object.id.to_s
  end

  field :meta do |object|
    object.file.meta
  end

  field :url do |object|
    if object.not_processed?
      nil
    elsif object.needs_redownload?
      media_proxy_url(object.id, :original)
    else
      full_asset_url(object.file.url(:original))
    end
  end

  field :preview_url do |object|
    if object.needs_redownload?
      media_proxy_url(object.id, :small)
    elsif object.thumbnail.present?
      full_asset_url(object.thumbnail.url(:original))
    elsif object.file.styles.key?(:small)
      full_asset_url(object.file.url(:small))
    end
  end

  field :remote_url do |object|
    object.remote_url.presence
  end

  field :preview_remote_url do |object|
    object.thumbnail_remote_url.presence
  end

  field :text_url do |object|
    object.local? && object.shortcode.present? ? medium_url(object) : nil
  end
end
