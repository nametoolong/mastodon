# frozen_string_literal: true

class REST::ApplicationSerializer < Blueprinter::Base
  view :public do
    field :name

    field :website do |object|
      object.website.presence
    end
  end

  view :confirmed do
    include_view :public

    field :vapid_key do
      Rails.configuration.x.vapid_public_key
    end
  end

  view :full do
    include_view :confirmed

    field :redirect_uri

    field :id do |object|
      object.id.to_s
    end

    field :client_id do |object|
      object.uid
    end

    field :client_secret do |object|
      object.secret
    end
  end
end
