# frozen_string_literal: true

class AfterBlockDomainFromAccountService < BaseService
  # This service does not create an AccountDomainBlock record,
  # it's meant to be called after such a record has been created
  # synchronously, to "clean up"
  def call(account, domain)
    @account = account
    @domain  = domain

    clear_notifications!
    remove_follows!
    reject_existing_followers!
    reject_pending_follow_requests!
  end

  private

  def remove_follows!
    @account.active_relationships.where(target_account: Account.where(domain: @domain)).includes(:target_account).reorder(nil).find_each do |follow|
      UnfollowService.new.call(@account, follow.target_account)
    end
  end

  def clear_notifications!
    Notification.where(account: @account).where(from_account: Account.where(domain: @domain)).in_batches.delete_all
  end

  def reject_existing_followers!
    @account.passive_relationships.where(account: Account.where(domain: @domain)).includes(:account).reorder(nil).find_each do |follow|
      reject_follow!(follow)
    end
  end

  def reject_pending_follow_requests!
    FollowRequest.where(target_account: @account).where(account: Account.where(domain: @domain)).includes(:account).reorder(nil).find_each do |follow_request|
      reject_follow!(follow_request)
    end
  end

  def reject_follow!(follow)
    follow.destroy

    return unless follow.account.activitypub?

    ActivityPub::DeliveryWorker.perform_async(Oj.dump(ActivityPub::Renderer.new(:reject_follow, follow).render), @account.id, follow.account.inbox_url)
  end
end
