# frozen_string_literal: true

class EmojisController < ApplicationController
  before_action :set_emoji
  before_action :set_cache_headers

  def show
    respond_to do |format|
      format.json do
        expires_in 3.minutes, public: true
        render_with_cache(content_type: 'application/activity+json') { ActivityPub::Renderer.new(:emoji, @emoji).render }
      end
    end
  end

  private

  def set_emoji
    @emoji = CustomEmoji.local.find(params[:id])
  end
end
