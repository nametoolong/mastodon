# frozen_string_literal: true

class Web::NotificationSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  fields :access_token, :body, :title, :preferred_locale

  field :id, name: :notification_id
  field :type, name: :notification_type

  field :icon do |object|
    full_asset_url(object.icon.url(:static))
  end
end
