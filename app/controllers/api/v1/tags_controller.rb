# frozen_string_literal: true

class Api::V1::TagsController < Api::BaseController
  include BlueprintHelper

  before_action -> { doorkeeper_authorize! :follow, :write, :'write:follows' }, except: :show
  before_action :require_user!, except: :show
  before_action :set_or_create_tag

  override_rate_limit_headers :follow, family: :follows

  def show
    render json: render_blueprint_with_account(REST::TagSerializer, @tag)
  end

  def follow
    TagFollow.create_with(rate_limit: true).find_or_create_by!(tag: @tag, account: current_account)
    render json: render_blueprint_with_account(REST::TagSerializer, @tag)
  end

  def unfollow
    TagFollow.find_by(account: current_account, tag: @tag)&.destroy!
    render json: render_blueprint_with_account(REST::TagSerializer, @tag)
  end

  private

  def set_or_create_tag
    return not_found unless Tag::HASHTAG_NAME_RE.match?(params[:id])
    @tag = Tag.find_normalized(params[:id]) || Tag.new(name: Tag.normalize(params[:id]), display_name: params[:id])
  end
end
