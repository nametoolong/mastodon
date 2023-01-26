# frozen_string_literal: true

class REST::RoleSerializer < Blueprinter::Base
  field :id do |object|
    object.id.to_s
  end

  view :public do
    fields :name, :color
  end

  view :full do
    include_view :public

    field :highlighted

    field :permissions do |object|
      object.computed_permissions.to_s
    end
  end
end
