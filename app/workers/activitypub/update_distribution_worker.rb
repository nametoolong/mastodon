# frozen_string_literal: true

class ActivityPub::UpdateDistributionWorker < ActivityPub::RawDistributionWorker
  sidekiq_options queue: 'push', lock: :until_executed

  # Distribute an profile update to servers that might have a copy
  # of the account in question
  def perform(account_id, options = {})
    @options = options.with_indifferent_access
    @account = Account.find(account_id)

    distribute!
  rescue ActiveRecord::RecordNotFound
    true
  end

  protected

  def inboxes
    @inboxes ||= AccountReachFinder.new(@account).inboxes
  end

  def payload
    @payload ||= Oj.dump(ActivityPub::Renderer.new(:update_actor, @account).render(signer: @account, sign_with: @options[:sign_with]))
  end
end
