# frozen_string_literal: true

class REST::Keys::ClaimResultSerializer < Blueprinter::Base
  fields :device_id, :key_id, :key, :signature

  field :account_id do |object|
    object.account.id.to_s
  end
end
