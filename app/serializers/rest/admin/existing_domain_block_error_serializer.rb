# frozen_string_literal: true

class REST::Admin::ExistingDomainBlockErrorSerializer < Blueprinter::Base
  field :error do |object|
    I18n.t('admin.domain_blocks.existing_domain_block', name: object.domain)
  end

  association :itself, name: :existing_domain_block, blueprint: REST::Admin::DomainBlockSerializer
end
