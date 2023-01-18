# frozen_string_literal: true

class NodeInfo::Serializer < Blueprinter::Base
  field :version do
    '2.0'
  end

  field :software do
    { name: 'mastodon', version: Mastodon::Version.to_s }
  end

  field :services do
    { outbound: [], inbound: [] }
  end

  field :protocols do
    %w(activitypub)
  end

  field :usage do |object|
    {
      users: {
        total: object.user_count,
        active_month: object.active_user_count(4),
        active_halfyear: object.active_user_count(24),
      },

      local_posts: object.status_count,
    }
  end

  field :open_registrations do |object|
    object.registrations_mode != 'none' && !Rails.configuration.x.single_user_mode
  end

  field :metadata do
    {}
  end

  transform NodeInfo::Transformer
end
