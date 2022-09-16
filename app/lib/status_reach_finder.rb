# frozen_string_literal: true

class StatusReachFinder
  # @param [Status] status
  # @param [Hash] options
  # @option options [Boolean] :unsafe
  def initialize(status, options = {})
    @status  = status
    @options = options
  end

  def inboxes
    (reached_account_inboxes + followers_inboxes + relay_inboxes).uniq
  end

  private

  def reached_account_inboxes
    # When the status is a reblog, there are no interactions with it
    # directly, we assume all interactions are with the original one

    if @status.reblog?
      []
    else
      Account.where(id: reached_account_ids).inboxes
    end
  end

  def reached_account_ids
    ids = Set.new

    ids << replied_to_account_id if distributable?
    ids << reblog_of_account_id if @status.reblog?

    ids.merge(mentioned_account_ids)

    # Beware: see comments for the corresponding methods
    if distributable? || unsafe?
      ids.merge(reblogs_account_ids)
      ids.merge(favourites_account_ids)
      ids.merge(replies_account_ids)
    end

    ids.to_a
  end

  def replied_to_account_id
    @status.in_reply_to_account_id
  end

  def reblog_of_account_id
    @status.reblog.account_id
  end

  def mentioned_account_ids
    @status.mentions.pluck(:account_id)
  end

  # Beware: Reblogs can be created without the author having had access to the status
  def reblogs_account_ids
    @status.reblogs.pluck(:account_id)
  end

  # Beware: Favourites can be created without the author having had access to the status
  def favourites_account_ids
    @status.favourites.pluck(:account_id)
  end

  # Beware: Replies can be created without the author having had access to the status
  def replies_account_ids
    @status.replies.pluck(:account_id)
  end

  def followers_inboxes
    if @status.in_reply_to_local_account? && distributable?
      @status.account.followers.or(@status.thread.account.followers).inboxes
    elsif @status.direct_visibility? || @status.limited_visibility?
      []
    else
      @status.account.followers.inboxes
    end
  end

  def relay_inboxes
    if @status.public_visibility?
      Relay.enabled.pluck(:inbox_url)
    else
      []
    end
  end

  def distributable?
    @status.public_visibility? || @status.unlisted_visibility?
  end

  def unsafe?
    @options[:unsafe]
  end
end
