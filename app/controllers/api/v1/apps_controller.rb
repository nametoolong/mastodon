# frozen_string_literal: true

class Api::V1::AppsController < Api::BaseController
  skip_before_action :require_authenticated_user!

  def create
    @app = Doorkeeper::Application.create!(application_options)
    render json: REST::ApplicationSerializer.render(@app, view: :full)
  end

  private

  def application_options
    {
      name: app_params[:client_name],
      redirect_uri: app_params[:redirect_uris],
      scopes: app_scopes_or_default,
      website: app_params[:website],
    }
  end

  def app_scopes_or_default
    app_params[:scopes] || Doorkeeper.configuration.default_scopes
  end

  def app_params
    params.permit(:client_name, :redirect_uris, :scopes, :website)
  end
end
