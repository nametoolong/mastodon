# frozen_string_literal: true

class REST::Admin::DomainBlockSerializer < Blueprinter::Base
  fields :domain, :created_at, :severity,
         :reject_media, :reject_reports,
         :private_comment, :public_comment, :obfuscate

  field :id do |object|
    object.id.to_s
  end
end
