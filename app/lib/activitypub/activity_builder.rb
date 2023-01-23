# frozen_string_literal: true

class ActivityPub::ActivityBuilder
  include RoutingHelper

  attr_reader :activity

  def initialize(intent, object, prerendered_object = nil)
    @object = object

    @activity = {
      type: intent.to_s.split("_", 2)[0].tap(&:capitalize!),
      object: prerendered_object
    }

    @activity.merge!(send(intent))
  end

  private

  attr_reader :object

  def accept_follow
    {
      id: [ActivityPub::TagManager.instance.uri_for(object.target_account), '#accepts/follows/', object.id].join,
      actor: ActivityPub::TagManager.instance.uri_for(object.target_account),
      to: ActivityPub::TagManager.instance.uri_for(object.account)
    }
  end

  def add
    {
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      target: account_collection_url(object.account, :featured),
      object: ActivityPub::TagManager.instance.uri_for(object)
    }
  end

  def add_featured_tag
    {
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      target: account_collection_url(object.account, :featured)
    }
  end

  def announce
    {
      id: ActivityPub::TagManager.instance.activity_uri_for(object),
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      published: object.created_at.iso8601,
      to: ActivityPub::TagManager.instance.to(object),
      cc: ActivityPub::TagManager.instance.cc(object),
    }
  end

  def create_encrypted_message
    {
      id: ActivityPub::TagManager.instance.generate_uri_for(nil),
      actor: ActivityPub::TagManager.instance.uri_for(object.source_account),
      published: Time.now.utc.iso8601,
      to: ActivityPub::TagManager.instance.uri_for(object.target_account)
    }
  end

  def create
    {
      id: ActivityPub::TagManager.instance.activity_uri_for(object),
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      published: object.created_at.iso8601,
      to: ActivityPub::TagManager.instance.to(object),
      cc: ActivityPub::TagManager.instance.cc(object),
    }
  end

  def create_vote
    {
      id: [ActivityPub::TagManager.instance.uri_for(object.account), '#votes/', object.id, '/activity'].join,
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      to: ActivityPub::TagManager.instance.uri_for(object.poll.account)
    }
  end

  def delete_actor
    {
      id: [ActivityPub::TagManager.instance.uri_for(object), '#delete'].join,
      actor: ActivityPub::TagManager.instance.uri_for(object),
      to: [ActivityPub::TagManager::COLLECTIONS[:public]]
    }
  end

  def delete_past_note
    {
      id: [ActivityPub::TagManager.instance.uri_for(object), '#delete'].join,
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      to: [ActivityPub::TagManager::COLLECTIONS[:public]]
    }
  end

  def remove
    {
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      target: account_collection_url(object.account, :featured),
      object: ActivityPub::TagManager.instance.uri_for(object)
    }
  end

  def remove_featured_tag
    {
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      target: account_collection_url(object.account, :featured)
    }
  end

  def reject_follow
    {
      id: [ActivityPub::TagManager.instance.uri_for(object.target_account), '#rejects/follows/', object.id].join,
      actor: ActivityPub::TagManager.instance.uri_for(object.target_account),
      to: ActivityPub::TagManager.instance.uri_for(object.account)
    }
  end

  def undo_announce
    {
      id: [ActivityPub::TagManager.instance.uri_for(object.account), '#announces/', object.id, '/undo'].join,
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      to: [ActivityPub::TagManager::COLLECTIONS[:public]]
    }
  end

  def undo_block
    {
      id: [ActivityPub::TagManager.instance.uri_for(object.account), '#blocks/', object.id, '/undo'].join,
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      to: ActivityPub::TagManager.instance.uri_for(object.target_account)
    }
  end

  def undo_follow
    {
      id: [ActivityPub::TagManager.instance.uri_for(object.account), '#follows/', object.id, '/undo'].join,
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      to: ActivityPub::TagManager.instance.uri_for(object.target_account)
    }
  end

  def undo_like
    {
      id: [ActivityPub::TagManager.instance.uri_for(object.account), '#likes/', object.id, '/undo'].join,
      actor: ActivityPub::TagManager.instance.uri_for(object.account)
    }
  end

  def update_actor
    {
      id: [ActivityPub::TagManager.instance.uri_for(object), '#updates/', object.updated_at.to_i].join,
      actor: ActivityPub::TagManager.instance.uri_for(object),
      to: [ActivityPub::TagManager::COLLECTIONS[:public]]
    }
  end

  def update_note
    last_edited_at = [object.edited_at.to_i, object.preloadable_poll.updated_at.to_i].max

    {
      id: [ActivityPub::TagManager.instance.uri_for(object), '#updates/', last_edited_at].join,
      actor: ActivityPub::TagManager.instance.uri_for(object.account),
      published: Time.at(last_edited_at).utc.iso8601,
      to: ActivityPub::TagManager.instance.to(object),
      cc: ActivityPub::TagManager.instance.cc(object)
    }
  end
end
