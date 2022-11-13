# frozen_string_literal: true

class REST::ReportSerializer < Blueprinter::Base
  fields :action_taken, :action_taken_at, :category, :comment,
         :forwarded, :created_at

  field :id do |object|
    object.id.to_s
  end

  field :status_ids do |object|
    object&.status_ids&.map(&:to_s)
  end

  field :rule_ids do |object|
    object&.rule_ids&.map(&:to_s)
  end

  association :target_account, blueprint: REST::AccountSerializer
end
