# frozen_string_literal: true

class REST::Admin::DomainAllowSerializer < Blueprinter::Base
  fields :domain, :created_at

  field :id do |object|
    object.id.to_s
  end
end
