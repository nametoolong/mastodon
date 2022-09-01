# frozen_string_literal: true

class REST::V1::FilterSerializer < Blueprinter::Base
  field :id do |object|
    object.id.to_s
  end

  field :keyword, name: :phrase

  field :whole_word

  field :context do |object|
    object.custom_filter.context
  end

  field :expires_at do |object|
    object.custom_filter.expires_at
  end

  field :irreversible do |object|
    object.custom_filter.irreversible?
  end
end
