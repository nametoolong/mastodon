# frozen_string_literal: true

module StaticRoutingHelper
  def full_asset_url(source, **options)
    source = ActionController::Base.helpers.asset_url(source, **options) unless use_storage?

    URI.join(asset_host, source).to_s
  end

  def tag_url(tag)
    Rails.application.routes.url_helpers.tag_url(tag, host: ActionMailer::Base.default_url_options[:host])
  end

  def medium_url(media)
    Rails.application.routes.url_helpers.medium_url(media, host: ActionMailer::Base.default_url_options[:host])
  end

  def media_proxy_url(*args)
    Rails.application.routes.url_helpers.media_proxy_url(*args, host: ActionMailer::Base.default_url_options[:host])
  end

  private

  def asset_host
    @root_url ||= begin
      Rails.configuration.action_controller.asset_host ||
      Rails.application.routes.url_helpers.root_url(host: ActionMailer::Base.default_url_options[:host])
    end
  end

  def use_storage?
    Rails.configuration.x.use_s3 || Rails.configuration.x.use_swift
  end
end
