# frozen_string_literal: true

class Api::V1::Statuses::ReblogsController < Api::BaseController
  include Authorization
  include BlueprintHelper

  before_action -> { doorkeeper_authorize! :write, :'write:statuses' }
  before_action :require_user!
  before_action :set_reblog, only: [:create]

  override_rate_limit_headers :create, family: :statuses

  def create
    @status = ReblogService.new.call(current_account, @reblog, reblog_params)

    render json: render_blueprint_with_account(REST::StatusSerializer, @status)
  end

  def destroy
    @status = current_account.statuses.find_by(reblog_of_id: params[:status_id])

    if @status
      authorize @status, :unreblog?
      @status.discard
      RemovalWorker.perform_async(@status.id)
      @reblog = @status.reblog
    else
      @reblog = Status.find(params[:status_id])
      authorize @reblog, :show?
    end

    render json: render_blueprint_with_account(REST::StatusSerializer, @reblog, relationships: StatusRelationshipsPresenter.new([@status], current_account.id, reblogs_map: { @reblog.id => false }))
  rescue Mastodon::NotPermittedError
    not_found
  end

  private

  def set_reblog
    @reblog = Status.find(params[:status_id])
    authorize @reblog, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def reblog_params
    params.permit(:visibility)
  end
end
