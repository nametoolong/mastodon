# frozen_string_literal: true

class REST::EncryptedMessageSerializer < Blueprinter::Base
  fields :type, :body, :digest, :message_franking,
         :created_at

  field :id do |object|
    object.id.to_s
  end

  field :account_id do |object|
    object.from_account_id.to_s
  end

  field :device_id do |object|
    object.from_device_id
  end
end
