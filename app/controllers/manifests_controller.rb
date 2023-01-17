# frozen_string_literal: true

class ManifestsController < ApplicationController
  skip_before_action :store_current_location
  skip_before_action :require_functional!

  def show
    expires_in 3.minutes, public: true
    render json: ManifestSerializer.render({})
  end
end
