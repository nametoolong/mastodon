# frozen_string_literal: true

module StatusSnapshotConcern
  extend ActiveSupport::Concern

  included do
    has_many :edits, class_name: 'StatusEdit', inverse_of: :status, dependent: :destroy
  end

  def edited?
    edited_at.present?
  end

  def prepare_snapshot_data(account_id: nil, at_time: nil)
    {
      status_id: id,
      text: text,
      spoiler_text: spoiler_text,
      sensitive: sensitive,
      ordered_media_attachment_ids: ordered_media_attachment_ids&.dup || media_attachments.pluck(:id),
      media_descriptions: ordered_media_attachments.map(&:description),
      poll_options: preloadable_poll&.options&.dup,
      account_id: account_id || self.account_id,
      created_at: at_time || edited_at
    }
  end

  def snapshot!(account_id: nil, at_time: nil, rate_limit: true)
    snapshot_data = prepare_snapshot_data(account_id: account_id, at_time: at_time)

    if rate_limit
      snapshot_data.merge!(rate_limit: true)
      StatusEdit.create!(snapshot_data)
    else
      snapshot_data.merge!(updated_at: Time.now.utc)
      StatusEdit.insert!(snapshot_data, returning: false)
    end
  end
end
