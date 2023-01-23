# frozen_string_literal: true

class ActivityPub::RawDistributionWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'push'

  # Base worker for when you want to queue up a bunch of deliveries of
  # some payload. In this case, we have already generated JSON and
  # we are going to distribute it to the account's followers minus
  # the explicitly provided inboxes
  def perform(json, source_account_id, exclude_inboxes = [])
    @account         = Account.find(source_account_id)
    @json            = json
    @exclude_inboxes = exclude_inboxes

    distribute!
  rescue ActiveRecord::RecordNotFound
    true
  end

  protected

  def distribute!
    return if inboxes.empty?

    ActivityPub::DeliveryWorker.push_bulk(inboxes) do |inbox_url|
      [payload, source_account_id, inbox_url, options.merge('account_cache_id' => account_cache_id)]
    end
  end

  def payload
    @json
  end

  def source_account_id
    @account.id
  end

  def account_cache_id
    @cache_id ||= RollingCache.new('mastoduck:delivery', 5000).push(@account, :id, :username, :domain, :private_key, :public_key, :uri, :url)
  end

  def inboxes
    @inboxes ||= @account.followers.inboxes - @exclude_inboxes
  end

  def options
    {}
  end
end
