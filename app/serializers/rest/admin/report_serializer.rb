# frozen_string_literal: true

class REST::Admin::ReportSerializer < Blueprinter::Base
  fields :action_taken, :action_taken_at, :category, :comment,
         :forwarded, :created_at, :updated_at

  field :id do |object|
    object.id.to_s
  end

  association :account, blueprint: REST::Admin::AccountSerializer
  association :target_account, blueprint: REST::Admin::AccountSerializer
  association :assigned_account, blueprint: REST::Admin::AccountSerializer
  association :action_taken_by_account, blueprint: REST::Admin::AccountSerializer

  association :rules, blueprint: REST::RuleSerializer

  view :guest do
    association :statuses, blueprint: REST::StatusSerializer, view: :guest do |object|
      object.statuses.with_includes
    end
  end

  view :logged_in do
    association :statuses, blueprint: REST::StatusSerializer, view: :logged_in do |object|
      object.statuses.with_includes
    end
  end
end
