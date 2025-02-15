# frozen_string_literal: true

class Api::V1::Trends::LinksController < Api::BaseController
  include BlueprintHelper

  before_action :set_links

  after_action :insert_pagination_headers

  DEFAULT_LINKS_LIMIT = 10

  def index
    render json: REST::Trends::LinkSerializer.render(@links)
  end

  private

  def enabled?
    Setting.trends
  end

  def set_links
    @links = begin
      if enabled?
        links_from_trends.offset(offset_param).limit(limit_param(DEFAULT_LINKS_LIMIT)).records
      else
        []
      end
    end
  end

  def links_from_trends
    scope = Trends.links.query.allowed.in_locale(content_locale)
    scope = scope.filtered_for(current_account) if user_signed_in?
    scope
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def next_path
    api_v1_trends_links_url pagination_params(offset: offset_param + limit_param(DEFAULT_LINKS_LIMIT)) if records_continue?
  end

  def prev_path
    api_v1_trends_links_url pagination_params(offset: offset_param - limit_param(DEFAULT_LINKS_LIMIT)) if offset_param > limit_param(DEFAULT_LINKS_LIMIT)
  end

  def records_continue?
    @links.size == limit_param(DEFAULT_LINKS_LIMIT)
  end

  def offset_param
    params[:offset].to_i
  end
end
