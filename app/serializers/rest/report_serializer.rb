# frozen_string_literal: true

class REST::ReportSerializer < Blueprinter::Base
  fields :action_taken, :action_taken_at, :category, :comment,
         :forwarded, :created_at, :status_ids, :rule_ids

  field :id do |object|
    object.id.to_s
  end

  association :target_account, blueprint: REST::AccountSerializer
end
