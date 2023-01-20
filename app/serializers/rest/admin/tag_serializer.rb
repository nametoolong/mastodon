# frozen_string_literal: true

class REST::Admin::TagSerializer < REST::TagSerializer
  fields :trendable, :usable

  field :requires_review?, name: :requires_review

  field :id do |object|
    object.id.to_s
  end
end
