# frozen_string_literal: true

module BatchWorkerConcern
  ACCOUNT_NOTIFY_FIELDS = [
    :id,
    :username,
    :domain,
    :note,
    :display_name,
    :fields,
    :suspended_at
  ].freeze

  ACCOUNT_NOTIFY_ATTRIBUTES = (ACCOUNT_NOTIFY_FIELDS + [:user]).freeze

  STATUS_FEED_ATTRIBUTES = [
    :id,
    :in_reply_to_id,
    :reblog_of_id,
    :reply,
    :language,
    :account_id,
    :in_reply_to_account_id
  ].freeze

  def push_in_batches(klass, query, first_batch:, remaining_batches:)
    query.reorder(nil).find_in_batches.with_index.each_with_object({}) do |(records, batch), context|
      jobs = (batch == 0 ? first_batch : remaining_batches).call(records, context)
      klass.perform_bulk(jobs)
    end
  end
end
