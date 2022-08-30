# frozen_string_literal: true

class REST::RoleSerializer < Blueprinter::Base
  fields :name, :color, :highlighted

  field :id do |object|
    object.id.to_s
  end

  field :permissions do |object|
    object.computed_permissions.to_s
  end
end
