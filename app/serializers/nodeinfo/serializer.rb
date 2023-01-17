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

  field :usage do
    instance_presenter = InstancePresenter.new

    {
      users: {
        total: instance_presenter.user_count,
        active_month: instance_presenter.active_user_count(4),
        active_halfyear: instance_presenter.active_user_count(24),
      },

      local_posts: instance_presenter.status_count,
    }
  end

  field :open_registrations do
    Setting.registrations_mode != 'none' && !Rails.configuration.x.single_user_mode
  end

  field :metadata do
    {}
  end

  transform NodeInfo::Transformer
end
