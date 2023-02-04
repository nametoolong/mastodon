# frozen_string_literal: true

class REST::InstanceSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  fields :domain, :title, :version, :source_url, :description,
         :languages

  field :thumbnail do |object|
    if object.thumbnail
      {
        url: full_asset_url(object.thumbnail.file.url(:'@1x')),
        blurhash: object.thumbnail.blurhash,
        versions: {
          '@1x': full_asset_url(object.thumbnail.file.url(:'@1x')),
          '@2x': full_asset_url(object.thumbnail.file.url(:'@2x')),
        },
      }
    else
      {
        url: full_pack_url('media/images/preview.png'),
      }
    end
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
      urls: {
        streaming: Rails.configuration.x.streaming_api_base_url,
        status: object.status_page_url,
      },

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

      translation: {
        enabled: TranslationService.configured?,
      },
    }
  end

  field :registrations do |object|
    enabled = object.registrations_mode != 'none' && !Rails.configuration.x.single_user_mode
    approval_required = object.registrations_mode == 'approved'
    message = object.closed_registrations_message unless enabled || object.closed_registrations_message.blank?
    message = Redcarpet::Markdown.new(Redcarpet::Render::HTML, no_images: true).render(message) if message.present?

    {
      enabled: enabled,
      approval_required: approval_required,
      message: message,
    }
  end

  class ContactSerializer < Blueprinter::Base
    field :email
    association :account, blueprint: REST::AccountSerializer
  end

  association :contact, blueprint: ContactSerializer
  association :rules, blueprint: REST::RuleSerializer
end
