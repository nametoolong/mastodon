# frozen_string_literal: true

class REST::Keys::QueryResultSerializer < Blueprinter::Base
  field :account_id do |object|
    object.account.id.to_s
  end

  association :devices, blueprint: REST::Keys::DeviceSerializer
end
