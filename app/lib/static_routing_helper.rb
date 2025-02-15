# frozen_string_literal: true

module StaticRoutingHelper
  def full_asset_url(source, **options)
    source = ActionController::Base.helpers.asset_url(source, options) unless use_storage?

    URI.join(asset_host, source).to_s
  end

  def full_pack_url(source, **options)
    full_asset_url(Webpacker.instance.manifest.lookup!(source), **options)
  end

  URL_HELPER_METHODS = %i(
    about_more_url
    account_url
    authorize_interaction_url
    embed_short_account_status_url
    instance_actor_url
    media_proxy_url
    medium_url
    nodeinfo_schema_url
    root_url
    short_account_tag_url
    short_account_url
    tag_url
  )

  URL_HELPER_METHODS.each do |name|
    define_method(name, ->(*args) { delegate_to_url_helper(name, args) })
  end

  private

  def asset_host
    @root_url ||= begin
      Rails.configuration.action_controller.asset_host || root_url(host: ActionMailer::Base.default_url_options[:host])
    end
  end

  def use_storage?
    Rails.configuration.x.use_s3 || Rails.configuration.x.use_swift
  end

  def delegate_to_url_helper(method, args)
    @url_helpers ||= Rails.application.routes.url_helpers
    @url_options ||= ActionMailer::Base.default_url_options
    @url_helpers.send(method, *args, **@url_options)
  end
end
