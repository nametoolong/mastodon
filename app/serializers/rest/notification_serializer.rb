# frozen_string_literal: true

class REST::NotificationSerializer < Blueprinter::Base
  fields :type, :created_at

  field :id do |object|
    object.id.to_s
  end

  association :from_account, name: :account, blueprint: REST::AccountSerializer

  view :guest do
  end

  view :logged_in do
    association :target_status, name: :status, if: ->(_name, object, options) {
      [:favourite, :reblog, :status, :mention, :poll, :update].include?(object.type)
    }, blueprint: REST::StatusSerializer, view: :logged_in

    association :report, if: ->(_name, object, options) {
      object.type == :'admin.report'
    }, blueprint: REST::ReportSerializer
  end
end
