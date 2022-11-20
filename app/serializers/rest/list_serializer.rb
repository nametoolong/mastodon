# frozen_string_literal: true

class REST::ListSerializer < Blueprinter::Base
  fields :title, :replies_policy

  field :id do |object|
    object.id.to_s
  end
end
