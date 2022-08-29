# frozen_string_literal: true

module StaticRoutingHelper
  def full_asset_url(source, **options)
    source = ActionController::Base.helpers.asset_url(source, **options) unless use_storage?

    URI.join(asset_host, source).to_s
  end

  def asset_host
    @root_url ||= (
      Rails.configuration.action_controller.asset_host ||
      Rails.application.routes.url_helpers.root_url(host: ActionMailer::Base.default_url_options[:host])
    )
  end

  def use_storage?
    Rails.configuration.x.use_s3 || Rails.configuration.x.use_swift
  end
end
