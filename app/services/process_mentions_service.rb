# frozen_string_literal: true

class ProcessMentionsService < BaseService
  include Payloadable

  # Scan status for mentions and fetch remote mentioned users, create
  # local mention pointers, send Salmon notifications to mentioned
  # remote users
  # @param [Status] status
  def call(status)
    @status = status

    return unless @status.local?

    mention_attributes = [:id, :account_id]
    @previous_mentions = @status.active_mentions.pluck(*mention_attributes).map! do |item|
      mention_attributes.zip(item).to_h
    end
    @current_mentions  = []

    Status.transaction do
      scan_text!
      assign_mentions!
    end
  end

  private

  def scan_text!
    @status.text = @status.text.gsub(Account::MENTION_RE) do |match|
      break if @current_mentions.length > Status::MAX_MENTIONS_PER_STATUS

      username, domain = Regexp.last_match(1).split('@')

      domain = begin
        if TagManager.instance.local_domain?(domain)
          nil
        else
          TagManager.instance.normalize_domain(domain)
        end
      end

      mentioned_account = Account.find_remote(username, domain)

      # Unapproved and unconfirmed accounts should not be mentionable
      next match if mentioned_account&.local? && !(mentioned_account.user_confirmed? && mentioned_account.user_approved?)

      # If the account cannot be found or isn't the right protocol,
      # first try to resolve it
      if mention_undeliverable?(mentioned_account)
        begin
          mentioned_account = ResolveAccountService.new.call(Regexp.last_match(1))
        rescue Webfinger::Error, HTTP::Error, OpenSSL::SSL::SSLError, Mastodon::UnexpectedResponseError
          mentioned_account = nil
        end
      end

      # If after resolving it still isn't found or isn't the right
      # protocol, then give up
      next match if mention_undeliverable?(mentioned_account) || mentioned_account&.suspended?

      mention   = @previous_mentions.find { |x| x[:account_id] == mentioned_account.id }
      mention ||= { account_id: mentioned_account.id }

      @current_mentions << mention

      "@#{mentioned_account.acct}"
    end

    @status.save!
  end

  def assign_mentions!
    if @current_mentions.length > Status::MAX_MENTIONS_PER_STATUS
      @status.active_mentions.update_all(silent: true)
      return
    end

    @current_mentions.uniq!

    # Make sure we never mention blocked accounts
    unless @current_mentions.empty?
      mentioned_account_ids    = @current_mentions.map { |x| x[:account_id] }
      mentioned_domain_by_acct = Hash[Account.where(id: mentioned_account_ids).pluck(:id, :domain)]
      mentioned_domains        = mentioned_domain_by_acct.values()
      mentioned_domains.compact!
      mentioned_domains.uniq!

      blocked_domains     = Set.new(mentioned_domains.empty? ? [] : AccountDomainBlock.where(account_id: @status.account_id, domain: mentioned_domains))
      blocked_account_ids = Set.new(@status.account.block_relationships.where(target_account_id: mentioned_account_ids).pluck(:target_account_id))
      blocked_account_ids.merge(mentioned_domain_by_acct.filter { |id, domain| blocked_domains.include?(domain) }.keys) unless blocked_domains.empty?

      @current_mentions.reject! { |x| blocked_account_ids.include?(x[:account_id]) }
    end

    default_attributes = {
      status_id: @status.id,
      created_at: Time.now.utc,
      updated_at: Time.now.utc,
    }

    new_mentions = @current_mentions.filter_map do |item|
      item.merge(default_attributes) unless item.include?(:id)
    end

    unless new_mentions.empty?
      Mention.insert_all!(new_mentions, returning: false)
      @status.mentions.reload
    end

    # If previous mentions are no longer contained in the text, convert them
    # to silent mentions, since withdrawing access from someone who already
    # received a notification might be more confusing
    removed_mentions = @previous_mentions - @current_mentions

    Mention.where(id: removed_mentions.map { |item| item[:id] }).update_all(silent: true) unless removed_mentions.empty?
  end

  def mention_undeliverable?(mentioned_account)
    mentioned_account.nil? || (!mentioned_account.local? && !mentioned_account.activitypub?)
  end
end
