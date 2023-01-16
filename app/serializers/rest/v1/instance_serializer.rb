# frozen_string_literal: true

class REST::V1::InstanceSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  fields :title, :version, :languages

  field :domain, name: :uri

  field :short_description do |object|
    object.description
  end

  field :description do
    Setting.site_description # Legacy
  end

  field :email do |object|
    object.contact.email
  end

  field :thumbnail do |object|
    object.thumbnail ? full_asset_url(object.thumbnail.file.url(:'@1x')) : full_pack_url('media/images/preview.png')
  end

  field :stats do |object|
    {
      user_count: object.user_count,
      status_count: object.status_count,
      domain_count: object.domain_count,
    }
  end

  field :urls do
    { streaming_api: Rails.configuration.x.streaming_api_base_url }
  end

  field :usage do |object|
    {
      users: {
        active_month: object.active_user_count(4),
      },
    }
  end

  field :configuration do
    {
      accounts: {
        max_featured_tags: FeaturedTag::LIMIT,
      },

      statuses: {
        max_characters: StatusLengthValidator::MAX_CHARS,
        max_media_attachments: 4,
        characters_reserved_per_url: StatusLengthValidator::URL_PLACEHOLDER_CHARS,
      },

      media_attachments: {
        supported_mime_types: MediaAttachment::IMAGE_MIME_TYPES + MediaAttachment::VIDEO_MIME_TYPES + MediaAttachment::AUDIO_MIME_TYPES,
        image_size_limit: MediaAttachment::IMAGE_LIMIT,
        image_matrix_limit: Attachmentable::MAX_MATRIX_LIMIT,
        video_size_limit: MediaAttachment::VIDEO_LIMIT,
        video_frame_rate_limit: MediaAttachment::MAX_VIDEO_FRAME_RATE,
        video_matrix_limit: MediaAttachment::MAX_VIDEO_MATRIX_LIMIT,
      },

      polls: {
        max_options: PollValidator::MAX_OPTIONS,
        max_characters_per_option: PollValidator::MAX_OPTION_CHARS,
        min_expiration: PollValidator::MIN_EXPIRATION,
        max_expiration: PollValidator::MAX_EXPIRATION,
      },
    }
  end

  field :registrations do |object|
    object.registrations_mode != 'none' && !Rails.configuration.x.single_user_mode
  end

  field :approval_required do |object|
    object.registrations_mode == 'approved'
  end

  field :invites_enabled do
    UserRole.everyone.can?(:invite_users)
  end

  association :rules, blueprint: REST::RuleSerializer
  association :contact_account, blueprint: REST::AccountSerializer do |object|
    object.contact.account
  end
end
