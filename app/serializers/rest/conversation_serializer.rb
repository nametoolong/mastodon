# frozen_string_literal: true

class REST::ConversationSerializer < Blueprinter::Base
  field :id do |object|
    object.id.to_s
  end

  field :unread

  association :participant_accounts, name: :accounts, blueprint: REST::AccountSerializer

  view :guest do
    association :last_status, blueprint: REST::StatusSerializer, view: :guest
  end

  view :logged_in do
    association :last_status, blueprint: REST::StatusSerializer, view: :logged_in
  end
end
