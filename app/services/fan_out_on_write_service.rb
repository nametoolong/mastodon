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
    push_in_batch(
      LocalNotificationWorker,
      @status.reblogged_by_accounts.merge(Account.local).includes(:user),
      first_batch: ->(records, context) {
        cache_ids = @cache.push_multi(records, :id, :username, :domain, :note, :display_name, :user, :fields, :suspended_at)
        context[:status] = @cache.push(@status, :id)
        records.zip(cache_ids).map! do |account, cache_id|
          [account.id, @status_id, 'Status', 'update', {
            'activity_cache_id' => context[:status],
            'receiver_cache_id' => cache_id
          }]
        end
      },
      remaining_batch: ->(records, context) {
        records.map! do |account|
          [account.id, @status_id, 'Status', 'update', {
            'activity_cache_id' => context[:status]
          }]
        end
      }
    )
  end

  def deliver_to_all_followers!
    push_in_batch(
      FeedInsertWorker,
      @account.followers_for_local_distribution.select(:id),
      first_batch: ->(records, context) {
        cache_ids = @cache.push_multi(records, :id)
        context[:status] = @cache.push(@status, :id, :in_reply_to_id, :reblog_of_id, :reply, :language, :account_id, :in_reply_to_account_id)
        records.zip(cache_ids).map! do |follower, cache_id|
          [@status_id, follower.id, 'home', {
            'update' => update?,
            'status_cache_id' => context[:status],
            'follower_cache_id' => cache_id
          }]
        end
      },
      remaining_batch: ->(records, context) {
        records.map! do |follower|
          [@status_id, follower.id, 'home', {
            'update' => update?,
            'status_cache_id' => context[:status]
          }]
        end
      }
    )
  end

  def deliver_to_hashtag_followers!
    push_in_batch(
      FeedInsertWorker,
      TagFollow.where(tag_id: @status.tags.map(&:id)).select(:id, :account_id),
      first_batch: ->(records, context) {
        cache_entries = records.map do |follow|
          {
            'type' => 'bson',
            'class' => 'Account',
            'content' => { id: follow.account_id }.to_bson.to_s
          }
        end
        cache_ids = @cache.push_direct_multi(cache_entries)
        context[:status] = @cache.push(@status, :id, :in_reply_to_id, :reblog_of_id, :reply, :language, :account_id, :in_reply_to_account_id)
        records.zip(cache_ids).map! do |follow, cache_id|
          [@status_id, follow.account_id, 'tags', {
            'update' => update?,
            'status_cache_id' => context[:status],
            'follower_cache_id' => cache_id
          }]
        end
      },
      remaining_batch: ->(records, context) {
        records.map! do |follow|
          [@status_id, follow.account_id, 'tags', {
            'update' => update?,
            'status_cache_id' => context[:status]
          }]
        end
      }
    )
  end

  def deliver_to_lists!
    push_in_batch(
      FeedInsertWorker,
      @account.lists_for_local_distribution.select(:id, :account_id),
      first_batch: ->(records, context) {
        list_cache_ids = @cache.push_multi(records, :id, :account_id)
        owner_cache_entries = records.map do |list|
          {
            'type' => 'bson',
            'class' => 'Account',
            'content' => { id: list.account_id }.to_bson.to_s
          }
        end
        owner_cache_ids = @cache.push_direct_multi(owner_cache_entries)
        context[:status] = @cache.push(@status, :id, :in_reply_to_id, :reblog_of_id, :reply, :language, :account_id, :in_reply_to_account_id)
        records.zip(list_cache_ids, owner_cache_ids).map! do |list, list_cache_id, owner_cache_id|
          [@status_id, list.id, 'list', {
            'update' => update?,
            'status_cache_id' => context[:status],
            'follower_cache_id' => owner_cache_id,
            'list_cache_id' => list_cache_id
          }]
        end
      },
      remaining_batch: ->(records, context) {
        records.map! do |list|
          [@status_id, list.id, 'list', {
            'update' => update?,
            'status_cache_id' => context[:status]
          }]
        end
      }
    )
  end

  def deliver_to_mentioned_followers!
    push_in_batch(
      FeedInsertWorker,
      @status.mentions.joins(:account).merge(@account.followers_for_local_distribution).select(:id, :account_id),
      first_batch: ->(records, context) {
        cache_entries = records.map do |mention|
          {
            'type' => 'bson',
            'class' => 'Account',
            'content' => { id: mention.account_id }.to_bson.to_s
          }
        end
        cache_ids = @cache.push_direct_multi(cache_entries)
        context[:status] = @cache.push(@status, :id, :in_reply_to_id, :reblog_of_id, :reply, :language, :account_id, :in_reply_to_account_id)
        records.zip(cache_ids).map! do |mention, cache_id|
          [@status_id, mention.account_id, 'home', {
            'update' => update?,
            'status_cache_id' => context[:status],
            'follower_cache_id' => cache_id
          }]
        end
      },
      remaining_batch: ->(records, context) {
        records.map! do |mention|
          [@status_id, mention.account_id, 'home', {
            'update' => update?,
            'status_cache_id' => context[:status]
          }]
        end
      }
    )
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

  def push_in_batch(klass, query, first_batch:, remaining_batch:)
    context = {}

    query.reorder(nil).find_in_batches(batch_size: 500).with_index do |records, batch|
      jobs = (batch == 0 ? first_batch : remaining_batch).call(records, context)
      klass.perform_bulk(jobs)
    end
  end
end
