# frozen_string_literal: true

class REST::WebPushSubscriptionSerializer < Blueprinter::Base
  fields :id, :endpoint

  field :alerts do |object|
    (object.data&.dig('alerts') || {}).transform_values { |v| ActiveModel::Type::Boolean.new.cast(v) }
  end

  field :server_key do
    Rails.configuration.x.vapid_public_key
  end
end
