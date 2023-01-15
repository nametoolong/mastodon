# frozen_string_literal: true

class PollExpirationNotifyWorker
  include BatchWorkerConcern
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed

  def perform(poll_id)
    @poll = Poll.find(poll_id)

    return if does_not_expire?
    requeue! && return if not_due_yet?

    @poll_id = @poll.id
    @cache = RollingCache.new('mastoduck:fanout', 10000)

    notify_remote_voters_and_owner! if @poll.local?
    notify_local_voters!
  rescue ActiveRecord::RecordNotFound
    true
  end

  def self.remove_from_scheduled(poll_id)
    queue = Sidekiq::ScheduledSet.new
    queue.select { |scheduled| scheduled.klass == name && scheduled.args[0] == poll_id }.map(&:delete)
  end

  private

  def does_not_expire?
    @poll.expires_at.nil?
  end

  def not_due_yet?
    @poll.expires_at.present? && !@poll.expired?
  end

  def requeue!
    PollExpirationNotifyWorker.perform_at(@poll.expires_at + 5.minutes, @poll_id)
  end

  def notify_remote_voters_and_owner!
    ActivityPub::DistributePollUpdateWorker.perform_async(@poll.status.id)
    LocalNotificationWorker.perform_async(@poll.account_id, @poll_id, 'Poll', 'poll')
  end

  def notify_local_voters!
    push_in_batches(
      LocalNotificationWorker,
      @poll.voters.merge(Account.local).select(*ACCOUNT_NOTIFY_FIELDS).includes(:user),
      first_batch: ->(records, context) {
        cache_ids = @cache.push_multi(records, *ACCOUNT_NOTIFY_ATTRIBUTES)
        context[:poll] = @cache.push(@poll, :id, :account_id)
        records.zip(cache_ids).map! do |account, cache_id|
          [account.id, @poll_id, 'Poll', 'poll', {
            'activity_cache_id' => context[:poll],
            'receiver_cache_id' => cache_id
          }]
        end
      },
      remaining_batches: ->(records, context) {
        records.map! do |account|
          [account.id, @poll_id, 'Poll', 'poll', {
            'activity_cache_id' => context[:poll]
          }]
        end
      }
    )
  end
end
