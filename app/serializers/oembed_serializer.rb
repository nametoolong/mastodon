# frozen_string_literal: true

class OEmbedSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  OEMBED_TEMPLATE = <<~HAML
    %iframe{ src: iframe_src, class: "mastodon-embed", style: "max-width: 100%; border: 0", allow: "fullscreen", **dimensions }
    %script{ src: script_src, async: "true" }
  HAML

  field :type do
    'rich'
  end

  field :version do
    '1.0'
  end

  field :author_name do |object|
    object.account.display_name.presence || object.account.username
  end

  field :author_url do |object|
    short_account_url(object.account)
  end

  field :provider_name do
    Rails.configuration.x.local_domain
  end

  field :provider_url do
    root_url
  end

  field :cache_age do
    86_400
  end

  field :html do |object, options|
    dimensions = { width: options[:width], height: options[:height] }.compact!

    Hamlit::Template.new { OEMBED_TEMPLATE }.render(
      nil,
      iframe_src: embed_short_account_status_url(object.account, object),
      script_src: full_asset_url('embed.js', skip_pipeline: true),
      dimensions: dimensions
    )
  end

  field :width do |object, options|
    options[:width]
  end

  field :height do |object, options|
    options[:height]
  end
end
