# frozen_string_literal: true

class REST::StatusEditSerializer < Blueprinter::Base
  extend FormattingHelper

  fields :created_at, :spoiler_text, :sensitive

  field :content do |object|
    status_content_format(object)
  end

  field :poll, if: -> (_name, object, options) {
    object.poll_options.present?
  } do |object|
    { options: object.poll_options.map { |title| { title: title } } }
  end

  association :account, blueprint: REST::AccountSerializer
  association :emojis, blueprint: REST::CustomEmojiSerializer
  association :ordered_media_attachments, name: :media_attachments, blueprint: REST::MediaAttachmentSerializer
end
