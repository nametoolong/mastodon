# frozen_string_literal: true

class Api::V1::ReportsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write, :'write:reports' }, only: [:create]
  before_action :require_user!

  override_rate_limit_headers :create, family: :reports

  def create
    @report = ReportService.new.call(
      current_account,
      reported_account,
      report_params
    )

    render json: REST::ReportSerializer.render(@report)
  end

  private

  def reported_account
    Account.find(report_params[:account_id])
  end

  def report_params
    params.permit(:account_id, :comment, :category, :forward, status_ids: [], rule_ids: [])
  end
end
