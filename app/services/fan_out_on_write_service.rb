# frozen_string_literal: true

class FanOutOnWriteService < BaseService
  include Redisable

  # Push a status into home and mentions feeds
  # @param [Status] status
  # @param [Hash] options
  # @option options [Boolean] update
  # @option options [Array<Integer>] silenced_account_ids
  def call(status, options = {})
    @status    = status
    @account   = status.account
    @options   = options

    check_race_condition!

    # Squeeze a few milliseconds by caching status id
    @status_id = status.id
    @cache = RollingCache.new('mastoduck:fanout', 8000)

    fan_out_to_local_recipients!
    fan_out_to_public_recipients! if broadcastable?
    fan_out_to_public_streams! if broadcastable?
  end

  private

  def check_race_condition!
    # I don't know why but at some point we had an issue where
    # this service was being executed with status objects
    # that had a null visibility - which should not be possible
    # since the column in the database is not nullable.
    #
    # This check re-queues the service to be run at a later time
    # with the full object, if something like it occurs

    raise Mastodon::RaceConditionError if @status.visibility.nil?
  end

  def fan_out_to_local_recipients!
    deliver_to_self!
    notify_mentioned_accounts!
    notify_about_update! if update?

    case @status.visibility.to_sym
    when :public, :unlisted, :private
      deliver_to_all_followers!
      deliver_to_lists!
    when :limited
      deliver_to_mentioned_followers!
    else
      deliver_to_mentioned_followers!
      deliver_to_conversation!
    end
  end

  def fan_out_to_public_recipients!
    deliver_to_hashtag_followers!
  end

  def fan_out_to_public_streams!
    # Cache the payload first
    anonymous_payload

    redis.pipelined do
      broadcast_to_hashtag_streams!
      broadcast_to_public_streams!
    end
  end

  def deliver_to_self!
    FeedManager.instance.push_to_home(@account, @status, update: update?) if @account.local?
  end

  def notify_mentioned_accounts!
    @status.active_mentions.where.not(id: @options[:silenced_account_ids] || []).joins(:account).merge(Account.local).select(:id, :account_id).reorder(nil).find_in_batches do |mentions|
      LocalNotificationWorker.push_bulk(mentions) do |mention|
        [mention.account_id, mention.id, 'Mention', 'mention']
      end
    end
  end

  def notify_about_update!
    @status.reblogged_by_accounts.merge(Account.local).includes(:user).reorder(nil).find_in_batches(batch_size: 500).with_index do |accounts, batch|
      if batch == 0
        # Only cache the first batch
        cache_ids = @cache.push_multi(accounts, :id, :username, :domain, :note, :display_name, :user, :fields, :suspended_at)
        status_cache_id = @cache.push(@status, :id)
        jobs = accounts.zip(cache_ids).map! do |account, cache_id|
          [account.id, @status_id, 'Status', 'update', {
            'activity_cache_id' => status_cache_id,
            'receiver_cache_id' => cache_id
          }]
        end
      else
        jobs = accounts.map! do |account|
          [account.id, @status_id, 'Status', 'update', {
            'activity_cache_id' => status_cache_id
          }]
        end
      end

      LocalNotificationWorker.perform_bulk(jobs)
    end
  end

  def deliver_to_all_followers!
    @account.followers_for_local_distribution.select(:id).reorder(nil).find_in_batches(batch_size: 500).with_index do |followers, batch|
      if batch == 0
        # Only cache the first batch
        cache_ids = @cache.push_multi(followers, :id)
        status_cache_id = @cache.push(@status, :id, :in_reply_to_id, :reblog_of_id, :reblog, :reply, :language, :account_id, :in_reply_to_account_id)
        jobs = followers.zip(cache_ids).map! do |follower, cache_id|
          [@status_id, follower.id, 'home', {
            'update' => update?,
            'status_cache_id' => status_cache_id,
            'follower_cache_id' => cache_id
          }]
        end
      else
        jobs = followers.map! do |follower|
          [@status_id, follower.id, 'home', {
            'update' => update?,
            'status_cache_id' => status_cache_id
          }]
        end
      end

      FeedInsertWorker.perform_bulk(jobs)
    end
  end

  def deliver_to_hashtag_followers!
    TagFollow.where(tag_id: @status.tags.map(&:id)).select(:id, :account_id).includes(:account).reorder(nil).find_in_batches(batch_size: 500).with_index do |follows, batch|
      if batch == 0
        # Only cache the first batch
        cache_ids = @cache.push_multi(follows.map(&:account), :id)
        status_cache_id = @cache.push(@status, :id, :in_reply_to_id, :reblog_of_id, :reblog, :reply, :language, :account_id, :in_reply_to_account_id)
        jobs = follows.zip(cache_ids).map! do |follow, cache_id|
          [@status_id, follow.account_id, 'tags', {
            'update' => update?,
            'status_cache_id' => status_cache_id,
            'follower_cache_id' => cache_id
          }]
        end
      else
        jobs = follows.map! do |follow|
          [@status_id, follow.account_id, 'tags', {
            'update' => update?,
            'status_cache_id' => status_cache_id
          }]
        end
      end

      FeedInsertWorker.perform_bulk(jobs)
    end
  end

  def deliver_to_lists!
    @account.lists_for_local_distribution.select(:id, :account_id).includes(:account).reorder(nil).find_in_batches(batch_size: 500).with_index do |lists, batch|
      if batch == 0
        # Only cache the first batch
        cache_ids = @cache.push_multi(lists, :id, :account_id, :account)
        status_cache_id = @cache.push(@status, :id, :in_reply_to_id, :reblog_of_id, :reblog, :reply, :language, :account_id, :in_reply_to_account_id)
        jobs = lists.zip(cache_ids).map! do |list, cache_id|
          [@status_id, list.id, 'list', {
            'update' => update?,
            'status_cache_id' => status_cache_id,
            'list_cache_id' => cache_id
          }]
        end
      else
        jobs = lists.map! do |list|
          [@status_id, list.id, 'list', {
            'update' => update?,
            'status_cache_id' => status_cache_id
          }]
        end
      end

      FeedInsertWorker.perform_bulk(jobs)
    end
  end

  def deliver_to_mentioned_followers!
    @status.mentions.joins(:account).merge(@account.followers_for_local_distribution).select(:id, :account_id).includes(:account).reorder(nil).find_in_batches(batch_size: 500).with_index do |mentions, batch|
      if batch == 0
        # Only cache the first batch
        cache_ids = @cache.push_multi(mentions.map(&:account), :id)
        status_cache_id = @cache.push(@status, :id, :in_reply_to_id, :reblog_of_id, :reblog, :reply, :language, :account_id, :in_reply_to_account_id)
        jobs = mentions.zip(cache_ids).map! do |mention, cache_id|
          [@status_id, mention.account_id, 'home', {
            'update' => update?,
            'status_cache_id' => status_cache_id,
            'follower_cache_id' => cache_id
          }]
        end
      else
        jobs = mentions.map! do |follow|
          [@status_id, mention.account_id, 'home', {
            'update' => update?,
            'status_cache_id' => status_cache_id
          }]
        end
      end

      FeedInsertWorker.perform_bulk(jobs)
    end
  end

  def broadcast_to_hashtag_streams!
    @status.tags.map(&:name).each do |hashtag|
      redis.publish("timeline:hashtag:#{hashtag.mb_chars.downcase}", anonymous_payload)
      redis.publish("timeline:hashtag:#{hashtag.mb_chars.downcase}:local", anonymous_payload) if @status.local?
    end
  end

  def broadcast_to_public_streams!
    return if @status.reply? && @status.in_reply_to_account_id != @account.id

    redis.publish('timeline:public', anonymous_payload)
    redis.publish(@status.local? ? 'timeline:public:local' : 'timeline:public:remote', anonymous_payload)

    if @status.with_media?
      redis.publish('timeline:public:media', anonymous_payload)
      redis.publish(@status.local? ? 'timeline:public:local:media' : 'timeline:public:remote:media', anonymous_payload)
    end
  end

  def deliver_to_conversation!
    AccountConversation.add_status(@account, @status) unless update?
  end

  def anonymous_payload
    @anonymous_payload ||= {
      event: update? ? :'status.update' : :update,
      payload: InlineRenderer.render(@status, nil, :status)
    }.to_bson.to_s
  end

  def update?
    @options[:update]
  end

  def broadcastable?
    @status.public_visibility? && !@status.reblog? && !@account.silenced?
  end
end
