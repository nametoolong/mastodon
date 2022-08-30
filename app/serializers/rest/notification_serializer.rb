# frozen_string_literal: true

class REST::NotificationSerializer < ActiveModel::Serializer
  include BlueprintHelper

  attributes :id, :type, :created_at

  attribute :from_account, key: :account
  attribute :target_status, key: :status, if: :status_type?
  belongs_to :report, if: :report_type?, serializer: REST::ReportSerializer

  def id
    object.id.to_s
  end

  def status_type?
    [:favourite, :reblog, :status, :mention, :poll, :update].include?(object.type)
  end

  def report_type?
    object.type == :'admin.report'
  end

  def from_account
    REST::AccountSerializer.render_as_json(object.from_account) if object.from_account
  end

  def target_status
    render_as_json_with_account(REST::StatusSerializer, object.target_status) if object.target_status
  end
end
