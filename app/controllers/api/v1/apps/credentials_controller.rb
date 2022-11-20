# frozen_string_literal: true

class Api::V1::Apps::CredentialsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }

  def show
    render json: REST::ApplicationSerializer.render(doorkeeper_token.application, view: :confirmed)
  end
end
