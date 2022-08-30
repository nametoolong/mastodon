# frozen_string_literal: true

class Api::V1::FeaturedTags::SuggestionsController < Api::BaseController
  include BlueprintHelper

  before_action -> { doorkeeper_authorize! :read, :'read:accounts' }, only: :index
  before_action :require_user!
  before_action :set_recently_used_tags, only: :index

  def index
    render json: render_blueprint_with_account(REST::TagSerializer, @recently_used_tags, relationships: TagRelationshipsPresenter.new(@recently_used_tags, current_user&.account_id))
  end

  private

  def set_recently_used_tags
    @recently_used_tags = Tag.recently_used(current_account).where.not(id: current_account.featured_tags).limit(10)
  end
end
