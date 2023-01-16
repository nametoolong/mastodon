# frozen_string_literal: true

class REST::RuleSerializer < Blueprinter::Base
  field :text

  field :id do |object|
    object.id.to_s
  end
end
