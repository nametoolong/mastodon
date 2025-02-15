# frozen_string_literal: true

class Api::V1::Statuses::MutesController < Api::BaseController
  include Authorization
  include BlueprintHelper

  before_action -> { doorkeeper_authorize! :write, :'write:mutes' }
  before_action :require_user!
  before_action :set_status
  before_action :set_conversation

  def create
    current_account.mute_conversation!(@conversation)

    render json: render_blueprint_with_account(REST::StatusSerializer, @status)
  end

  def destroy
    current_account.unmute_conversation!(@conversation)

    render json: render_blueprint_with_account(REST::StatusSerializer, @status)
  end

  private

  def set_status
    @status = Status.find(params[:status_id])
    authorize @status, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def set_conversation
    @conversation = @status.conversation
    raise Mastodon::ValidationError if @conversation.nil?
  end
end
