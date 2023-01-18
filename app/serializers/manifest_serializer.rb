# frozen_string_literal: true

class ManifestSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  ICON_SIZES = %w(
    36
    48
    72
    96
    144
    192
    256
    384
    512
  ).freeze

  field :name do |object|
    object.title
  end

  field :short_name do |object|
    object.title
  end

  field :icons do
    ICON_SIZES.map do |size|
      {
        src: full_pack_url("media/icons/android-chrome-#{size}x#{size}.png"),
        sizes: "#{size}x#{size}",
        type: 'image/png',
        purpose: 'any maskable',
      }
    end
  end

  field :theme_color do
    '#191b22'
  end

  field :background_color do
    '#191b22'
  end

  field :display do
    'standalone'
  end

  field :start_url do
    '/home'
  end

  field :scope do
    '/'
  end

  field :share_target do
    {
      url_template: 'share?title={title}&text={text}&url={url}',
      action: 'share',
      method: 'GET',
      enctype: 'application/x-www-form-urlencoded',
      params: {
        title: 'title',
        text: 'text',
        url: 'url',
      },
    }
  end

  field :shortcuts do
    [
      {
        name: 'Compose new post',
        url: '/publish',
      },
      {
        name: 'Notifications',
        url: '/notifications',
      },
    ]
  end
end
