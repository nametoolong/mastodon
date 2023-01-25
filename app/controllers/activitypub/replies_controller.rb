# frozen_string_literal: true

class ActivityPub::RepliesController < ActivityPub::BaseController
  include SignatureVerification
  include Authorization
  include AccountOwnedConcern

  DESCENDANTS_LIMIT = 60

  before_action :require_account_signature!, if: :authorized_fetch_mode?
  before_action :set_status
  before_action :set_cache_headers
  before_action :set_replies
  before_action :preload_associations

  def index
    expires_in 0, public: public_fetch_mode?
    render json: ActivityPub::Renderer.new(:note, replies_collection_presenter, replies_map: @replies_map).render, content_type: 'application/activity+json'
  end

  private

  def pundit_user
    signed_request_account
  end

  def set_status
    @status = @account.statuses.find(params[:status_id])
    authorize @status, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def set_replies
    @replies = (only_remote? ? Status.remote : Status.local).joins(:account).merge(Account.without_suspended)
    @replies = @replies.where(in_reply_to_id: @status.id, visibility: [:public, :unlisted])
    @replies = @replies.paginate_by_min_id(DESCENDANTS_LIMIT, params[:min_id])

    if only_remote?
      @replies = @replies.select(:id, :uri)
    else
      @replies = @replies.preload(:account, :conversation, :media_attachments, :preloadable_poll, :tags, :thread, active_mentions: :account)
    end
  end

  def preload_associations
    @replies_map = Status.replies_map(@replies.map(&:id), only_local: true) unless only_remote?
  end

  def replies_collection_presenter
    page = ActivityPub::CollectionPresenter.new(
      id: account_status_replies_url(@account, @status, page_params),
      type: :unordered,
      part_of: account_status_replies_url(@account, @status),
      next: next_page,
      items: only_remote? ? @replies.map(&:uri) : @replies
    )

    return page if page_requested?

    ActivityPub::CollectionPresenter.new(
      id: account_status_replies_url(@account, @status),
      type: :unordered,
      first: page
    )
  end

  def page_requested?
    truthy_param?(:page)
  end

  def only_remote?
    truthy_param?(:only_remote)
  end

  def next_page
    ended = @replies.size < DESCENDANTS_LIMIT

    if only_remote?
      # Only consider remote accounts
      return nil if ended

      account_status_replies_url(
        @account,
        @status,
        page: true,
        min_id: @replies&.last&.id,
        only_remote: true
      )
    else
      # For now, we're serving only local replies, but next page might be remote replies
      account_status_replies_url(
        @account,
        @status,
        page: true,
        min_id: ended ? nil : @replies.last&.id,
        only_remote: ended
      )
    end
  end

  def page_params
    params_slice(:only_remote, :min_id).merge(page: true)
  end
end
