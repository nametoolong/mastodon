# frozen_string_literal: true

class Api::V1::Polls::VotesController < Api::BaseController
  include Authorization
  include BlueprintHelper

  before_action -> { doorkeeper_authorize! :write, :'write:statuses' }
  before_action :require_user!
  before_action :set_poll

  def create
    VoteService.new.call(current_account, @poll, vote_params[:choices])
    render json: render_blueprint_with_account(REST::PollSerializer, @poll)
  end

  private

  def set_poll
    @poll = Poll.attached.find(params[:poll_id])
    authorize @poll.status, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def vote_params
    params.permit(choices: [])
  end
end
