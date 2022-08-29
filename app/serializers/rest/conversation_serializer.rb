# frozen_string_literal: true

class REST::ConversationSerializer < ActiveModel::Serializer
  attributes :id, :unread

  attribute :participant_accounts, key: :accounts
  has_one :last_status, serializer: REST::StatusSerializer

  def id
    object.id.to_s
  end

  def participant_accounts
    REST::AccountSerializer.render_as_json(object.participant_accounts)
  end
end
