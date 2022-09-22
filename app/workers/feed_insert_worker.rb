# frozen_string_literal: true

class FeedInsertWorker
  include Sidekiq::Worker

  def perform(status_id, id, type = 'home', options = {})
    cache = RollingCache.new('mastoduck:fanout', 8000)

    @type      = type.to_sym
    @status    = cache.get(options['status_cache_id']) if options['status_cache_id']
    @status    = Status.find(status_id) if @status.nil?
    @options   = options.symbolize_keys

    case @type
    when :home, :tags
      @follower = cache.get(options['follower_cache_id']) if options['follower_cache_id']
      @follower = Account.find(id) if @follower.nil?
    when :list
      @list     = cache.get(options['list_cache_id']) if options['list_cache_id']
      @list     = List.find(id) if @list.nil?
      @follower = @list.account
    end

    check_and_insert
  rescue ActiveRecord::RecordNotFound
    true
  end

  private

  def check_and_insert
    if feed_filtered?
      perform_unpush if update?
    else
      perform_push
      perform_notify if notify?
    end
  end

  def feed_filtered?
    case @type
    when :home
      FeedManager.instance.filter?(:home, @status, @follower)
    when :tags
      FeedManager.instance.filter?(:tags, @status, @follower)
    when :list
      FeedManager.instance.filter?(:list, @status, @list)
    end
  end

  def notify?
    return false if @type != :home || @status.reblog? || (@status.reply? && @status.in_reply_to_account_id != @status.account_id)

    Follow.find_by(account: @follower, target_account_id: @status.account_id)&.notify?
  end

  def perform_push
    case @type
    when :home, :tags
      FeedManager.instance.push_to_home(@follower, @status, update: update?)
    when :list
      FeedManager.instance.push_to_list(@list, @status, update: update?)
    end
  end

  def perform_unpush
    case @type
    when :home, :tags
      FeedManager.instance.unpush_from_home(@follower, @status, update: true)
    when :list
      FeedManager.instance.unpush_from_list(@list, @status, update: true)
    end
  end

  def perform_notify
    LocalNotificationWorker.perform_async(@follower.id, @status.id, 'Status', 'status')
  end

  def update?
    @options[:update]
  end
end
