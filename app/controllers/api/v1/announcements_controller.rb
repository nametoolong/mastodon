# frozen_string_literal: true

class Api::V1::AnnouncementsController < Api::BaseController
  include BlueprintHelper

  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }, only: :dismiss
  before_action :require_user!
  before_action :set_announcements, only: :index
  before_action :set_announcement, except: :index

  def index
    render json: render_blueprint_with_account(REST::AnnouncementSerializer, @announcements)
  end

  def dismiss
    AnnouncementMute.find_or_create_by!(account: current_account, announcement: @announcement)
    render_empty
  end

  private

  def set_announcements
    @announcements = begin
      Announcement.published.chronological
    end
  end

  def set_announcement
    @announcement = Announcement.published.find(params[:id])
  end
end
