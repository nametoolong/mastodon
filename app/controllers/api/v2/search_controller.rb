# frozen_string_literal: true

class Api::V2::SearchController < Api::BaseController
  include Authorization
  include BlueprintHelper

  RESULTS_LIMIT = 20

  before_action -> { authorize_if_got_token! :read, :'read:search' }

  def index
    render json: render_blueprint_with_account(REST::SearchSerializer, search_results)
  rescue Mastodon::SyntaxError
    unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  private

  def search_results
    SearchService.new.call(
      params[:q],
      current_account,
      limit_param(RESULTS_LIMIT),
      search_params.merge(resolve: user_signed_in? ? truthy_param?(:resolve) : false, exclude_unreviewed: truthy_param?(:exclude_unreviewed))
    )
  end

  def search_params
    params.permit(:type, :offset, :min_id, :max_id, :account_id)
  end
end
