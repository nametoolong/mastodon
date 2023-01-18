# frozen_string_literal: true

module WellKnown
  class NodeInfoController < ActionController::Base
    include CacheConcern

    before_action { response.headers['Vary'] = 'Accept' }

    def index
      expires_in 3.days, public: true
      render_with_cache(expires_in: 3.days) { NodeInfo::DiscoverySerializer.render({}) }
    end

    def show
      expires_in 30.minutes, public: true
      render_with_cache(expires_in: 30.minutes) { NodeInfo::Serializer.render(SitePresenter.new) }
    end
  end
end
