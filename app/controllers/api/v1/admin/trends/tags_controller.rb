# frozen_string_literal: true

class Api::V1::Admin::Trends::TagsController < Api::V1::Trends::TagsController
  include BlueprintHelper

  before_action -> { authorize_if_got_token! :'admin:read' }

  def index
    if current_user&.can?(:manage_taxonomies)
      render json: render_blueprint_with_account(REST::Admin::TagSerializer, @tags)
    else
      super
    end
  end

  private

  def enabled?
    super || current_user&.can?(:manage_taxonomies)
  end

  def tags_from_trends
    if current_user&.can?(:manage_taxonomies)
      Trends.tags.query
    else
      super
    end
  end
end
