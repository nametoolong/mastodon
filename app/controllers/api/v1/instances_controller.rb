# frozen_string_literal: true

class Api::V1::InstancesController < Api::BaseController
  skip_before_action :set_cache_headers
  skip_before_action :require_authenticated_user!, unless: :whitelist_mode?

  def show
    expires_in 3.minutes, public: true
    render_with_cache { REST::V1::InstanceSerializer.render(InstancePresenter.new) }
  end
end
