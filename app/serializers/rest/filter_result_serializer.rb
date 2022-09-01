# frozen_string_literal: true

class REST::FilterResultSerializer < Blueprinter::Base
  field :keyword_matches

  field :status_matches do |object|
    object.status_matches&.map(&:to_s)
  end

  association :filter, blueprint: REST::FilterSerializer
end
