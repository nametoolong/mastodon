# frozen_string_literal: true

class REST::Admin::CanonicalEmailBlockSerializer < Blueprinter::Base
  field :canonical_email_hash

  field :id do |object|
    object.id.to_s
  end
end
