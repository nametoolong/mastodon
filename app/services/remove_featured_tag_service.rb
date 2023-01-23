# frozen_string_literal: true

class RemoveFeaturedTagService < BaseService
  def call(account, featured_tag)
    @account = account

    featured_tag.destroy!
    ActivityPub::AccountRawDistributionWorker.perform_async(build_json(featured_tag), account.id) if @account.local?
  end

  private

  def build_json(featured_tag)
    Oj.dump(ActivityPub::Renderer.new(:remove_featured_tag, featured_tag).render(signer: @account))
  end
end
