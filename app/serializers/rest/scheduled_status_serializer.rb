# frozen_string_literal: true

class REST::ScheduledStatusSerializer < Blueprinter::Base
  field :id do |object|
    object.id.to_s
  end

  field :scheduled_at

  field :params do |object|
    object.params.without(:application_id)
  end

  association :media_attachments, blueprint: REST::MediaAttachmentSerializer
end
