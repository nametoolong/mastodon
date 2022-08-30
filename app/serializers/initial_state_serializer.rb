# frozen_string_literal: true

class InitialStateSerializer < Blueprinter::Base
  field :meta do |object|
    instance_presenter = InstancePresenter.new

    store = {
      streaming_api_base_url: Rails.configuration.x.streaming_api_base_url,
      access_token: object[:token],
      locale: I18n.locale,
      domain: Rails.configuration.x.local_domain,
      title: instance_presenter.site_title,
      admin: object[:admin]&.id&.to_s,
      search_enabled: Chewy.enabled?,
      repository: Mastodon::Version.repository,
      source_url: Mastodon::Version.source_url,
      version: Mastodon::Version.to_s,
      limited_federation_mode: Rails.configuration.x.whitelist_mode,
      mascot: instance_presenter.mascot&.file&.url,
      profile_directory: Setting.profile_directory,
      trends: Setting.trends,
    }

    if object[:current_account]
      current_account = object[:current_account]
      store[:me]                = current_account.id.to_s
      store[:unfollow_modal]    = current_account.user.setting_unfollow_modal
      store[:boost_modal]       = current_account.user.setting_boost_modal
      store[:delete_modal]      = current_account.user.setting_delete_modal
      store[:auto_play_gif]     = current_account.user.setting_auto_play_gif
      store[:display_media]     = current_account.user.setting_display_media
      store[:expand_spoilers]   = current_account.user.setting_expand_spoilers
      store[:reduce_motion]     = current_account.user.setting_reduce_motion
      store[:disable_swiping]   = current_account.user.setting_disable_swiping
      store[:advanced_layout]   = current_account.user.setting_advanced_layout
      store[:use_blurhash]      = current_account.user.setting_use_blurhash
      store[:use_pending_items] = current_account.user.setting_use_pending_items
      store[:trends]            = Setting.trends && current_account.user.setting_trends
      store[:crop_images]       = current_account.user.setting_crop_images
    else
      store[:auto_play_gif] = Setting.auto_play_gif
      store[:display_media] = Setting.display_media
      store[:reduce_motion] = Setting.reduce_motion
      store[:use_blurhash]  = Setting.use_blurhash
      store[:crop_images]   = Setting.crop_images
    end

    store
  end

  field :compose do |object|
    store = {}

    if object[:current_account]
      current_account = object[:current_account]
      store[:me]                = current_account.id.to_s
      store[:default_privacy]   = object[:visibility] || current_account.user.setting_default_privacy
      store[:default_sensitive] = current_account.user.setting_default_sensitive
      store[:default_language]  = current_account.user.preferred_posting_language
    end

    store[:text] = object[:text] if object[:text]

    store
  end

  field :accounts do |object|
    store = {}

    current_account = object[:current_account]
    admin = object[:admin]
    store[current_account.id.to_s] = REST::AccountSerializer.render_as_json(current_account) if current_account
    store[admin.id.to_s]           = REST::AccountSerializer.render_as_json(admin) if admin

    store
  end

  field :media_attachments do |object|
    { accept_content_types: MediaAttachment.supported_file_extensions + MediaAttachment.supported_mime_types }
  end

  field :languages do |object|
    LanguagesHelper::SUPPORTED_LOCALES.map { |(key, value)| [key, value[0], value[1]] }
  end

  field :push_subscription do |object|
    REST::WebPushSubscriptionSerializer.new(object[:push_subscription]).as_json if object[:push_subscription]
  end

  field :settings

  association :role, blueprint: REST::RoleSerializer
end
