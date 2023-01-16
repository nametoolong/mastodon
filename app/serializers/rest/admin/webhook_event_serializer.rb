# frozen_string_literal: true

class REST::Admin::WebhookEventSerializer < Blueprinter::Base
  field :created_at

  field :type, name: :event

  view :account do
    association :object, blueprint: REST::Admin::AccountSerializer
  end

  view :report do
    association :object, blueprint: REST::Admin::ReportSerializer, view: :guest
  end
end
