# frozen_string_literal: true

class REST::DomainBlockSerializer < Blueprinter::Base
  view :without_comment do
    field :severity
    field :public_domain, name: :domain
    field :domain_digest, name: :digest
  end

  view :with_comment do
    include_view :without_comment
    field :public_comment, name: :comment
  end
end
