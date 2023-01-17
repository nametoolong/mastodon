# frozen_string_literal: true

class REST::Admin::EmailDomainBlockSerializer < Blueprinter::Base
  fields :domain, :created_at

  field :id do |object|
    object.id.to_s
  end

  field :history do |object|
    object.history.as_json
  end
end
