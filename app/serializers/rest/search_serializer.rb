# frozen_string_literal: true

class REST::SearchSerializer < Blueprinter::Base
  association :accounts, blueprint: REST::AccountSerializer do |object|
    object[:accounts]
  end

  field :statuses do |object|
    ActiveModel::Serializer::CollectionSerializer.new(
      object[:statuses],
      serializer: REST::StatusSerializer
    ).as_json
  end

  field :hashtags do |object|
    ActiveModel::Serializer::CollectionSerializer.new(
      object[:hashtags],
      serializer: REST::TagSerializer
    ).as_json
  end
end
