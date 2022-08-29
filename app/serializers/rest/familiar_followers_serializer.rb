# frozen_string_literal: true

class REST::FamiliarFollowersSerializer < Blueprinter::Base
  field :id do |object|
    object.id.to_s
  end

  association :accounts, blueprint: REST::AccountSerializer
end
