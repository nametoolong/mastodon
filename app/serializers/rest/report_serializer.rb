# frozen_string_literal: true

class REST::ReportSerializer < ActiveModel::Serializer
  attributes :id, :action_taken, :action_taken_at, :category, :comment,
             :forwarded, :created_at, :status_ids, :rule_ids, :target_account

  def id
    object.id.to_s
  end

  def target_account
    REST::AccountSerializer.render_as_json(object.target_account)
  end
end
