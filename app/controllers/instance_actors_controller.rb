# frozen_string_literal: true

class InstanceActorsController < ApplicationController
  include AccountControllerConcern

  skip_before_action :check_account_confirmation
  skip_around_action :set_locale

  def show
    expires_in 10.minutes, public: true
    render json: ActivityPub::Renderer.new(:actor, @account).render, content_type: 'application/activity+json'
  end

  private

  def set_account
    @account = Account.representative
  end
end
