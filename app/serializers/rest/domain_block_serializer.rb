# frozen_string_literal: true

class REST::DomainBlockSerializer < Blueprinter::Base
  field :severity

  field :public_domain, name: :domain
  field :domain_digest, name: :digest
  field :public_comment, name: :comment, if: ->(_name, object, options) {
    options[:with_comment]
  }
end
