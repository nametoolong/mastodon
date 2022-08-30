# frozen_string_literal: true

class REST::SearchSerializer < Blueprinter::Base
  association :accounts, blueprint: REST::AccountSerializer

  field :hashtags do |object|
    ActiveModel::Serializer::CollectionSerializer.new(
      object[:hashtags],
      serializer: REST::TagSerializer
    ).as_json
  end

  view :guest do
    association :statuses, blueprint: REST::StatusSerializer, view: :guest
  end

  view :logged_in do
    association :statuses, blueprint: REST::StatusSerializer, view: :logged_in
  end
end
