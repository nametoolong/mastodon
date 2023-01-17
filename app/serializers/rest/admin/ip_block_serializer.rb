# frozen_string_literal: true

class REST::Admin::IpBlockSerializer < Blueprinter::Base
  fields :severity, :comment, :created_at, :expires_at

  field :id do |object|
    object.id.to_s
  end

  field :ip do |object|
    "#{object.ip}/#{object.ip.prefix}"
  end
end
