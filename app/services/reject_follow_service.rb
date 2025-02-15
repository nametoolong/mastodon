# frozen_string_literal: true

class RejectFollowService < BaseService
  def call(source_account, target_account)
    follow_request = FollowRequest.find_by!(account: source_account, target_account: target_account)
    follow_request.reject!
    create_notification(follow_request) if !source_account.local? && source_account.activitypub?
    follow_request
  end

  private

  def create_notification(follow_request)
    ActivityPub::DeliveryWorker.perform_async(build_json(follow_request), follow_request.target_account_id, follow_request.account.inbox_url)
  end

  def build_json(follow_request)
    Oj.dump(ActivityPub::Renderer.new(:reject_follow, follow_request).render)
  end
end
