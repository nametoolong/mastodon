# frozen_string_literal: true

class ActivityPub::Renderer
  include ContextHelper

  OBJECT_SERIALIZERS = {
    actor:             ActivityPub::ActorSerializer,            # Account
    announce:          ActivityPub::AnnounceSerializer,         # Status
    block:             ActivityPub::BlockSerializer,            # Block
    device:            ActivityPub::DeviceSerializer,           # Device
    emoji:             ActivityPub::EmojiSerializer,            # CustomEmoji
    encrypted_message: ActivityPub::EncryptedMessageSerializer, # DeliverToDeviceService::EncryptedMessage
    featured_tag:      ActivityPub::HashtagSerializer,          # FeaturedTag
    flag:              ActivityPub::FlagSerializer,             # Report
    follow:            ActivityPub::FollowSerializer,           # Follow
    like:              ActivityPub::LikeSerializer,             # Favourite
    move:              ActivityPub::MoveSerializer,             # AccountMigration
    note:              ActivityPub::NoteSerializer,             # Status
    one_time_key:      ActivityPub::OneTimeKeySerializer,       # Keys::ClaimService::Result
    past_note:         ActivityPub::TombstoneSerializer,        # Status
    vote:              ActivityPub::VoteSerializer,             # PollVote
  }

  def initialize(intent, object, options = {})
    @intent             = intent
    @object             = object
    @options            = options

    @named_contexts     = { activitystreams: true }
    @context_extensions = {}
  end

  def render(signer: nil, sign_with: nil, always_sign: nil)
    serialized_hash = render_with_intent(@intent, @object)

    json = {
      '@context' => serialized_context(@named_contexts, @context_extensions)
    }.merge!(serialized_hash)

    if (@object.respond_to?(:sign?) && @object.sign?) && signer && (always_sign || signing_enabled?)
      ActivityPub::LinkedDataSignature.new(json).sign!(signer, sign_with: sign_with)
    else
      json
    end
  end

  private

  def render_with_intent(intent, object)
    if object.is_a?(ActivityPub::CollectionPresenter)
      ActivityPub::CollectionSerializer.new(
        prerender_collection_items(intent, object),
        @options
      ).as_json
    elsif OBJECT_SERIALIZERS.include?(intent)
      render_object(intent, object)
    elsif intent == :outbox
      render_outbox(object)
    else
      render_activity(intent, object)
    end
  end

  def render_object(object_type, object)
    serializer = OBJECT_SERIALIZERS[object_type]

    @named_contexts.merge!(serializer.named_contexts)
    @context_extensions.merge!(serializer.context_extensions)

    serializer.new(object, @options).as_json
  end

  def render_outbox(status)
    if status.reblog?
      should_inline = (
        status.account == status.proper.account &&
        status.proper.private_visibility? &&
        status.local?
      )

      prerendered_object = should_inline ?
        render_object(:note, status.proper) :
        ActivityPub::TagManager.instance.uri_for(status.proper)

      ActivityPub::ActivityBuilder.new(:announce, status, prerendered_object).activity
    else
      prerendered_object = render_object(:note, status.proper)

      ActivityPub::ActivityBuilder.new(:create, status, prerendered_object).activity
    end
  end

  def render_activity(intent, object)
    object_type = intent.to_s.split("_", 2)[1]&.to_sym
    prerendered_object = render_object(object_type, object) if object_type
    ActivityPub::ActivityBuilder.new(intent, object, prerendered_object).activity
  end

  def prerender_collection_items(intent, object)
    first = object.first
    last = object.last

    if first.is_a?(ActivityPub::CollectionPresenter)
      first = prerender_collection_items(intent, first)
    end

    if last.is_a?(ActivityPub::CollectionPresenter)
      last = prerender_collection_items(intent, last)
    end

    items = object.items&.map do |item|
      if item.is_a?(String)
        item
      else
        render_with_intent(intent, item)
      end
    end

    ActivityPub::CollectionPresenter.new(
      id: object.id,
      type: object.type,
      size: object.size,
      page: object.page,
      part_of: object.part_of,
      next: object.next,
      prev: object.prev,
      first: first,
      last: last,
      items: items
    )
  end

  def signing_enabled?
    ENV['AUTHORIZED_FETCH'] != 'true' && !Rails.configuration.x.whitelist_mode
  end
end
