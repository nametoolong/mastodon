# frozen_string_literal: true

class REST::FilterStatusSerializer < Blueprinter::Base
  field :id do |object|
    object.id.to_s
  end

  field :status_id do |object|
    object.status_id.to_s
  end
end
