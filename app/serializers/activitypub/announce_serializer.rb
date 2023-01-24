# frozen_string_literal: true

class ActivityPub::AnnounceSerializer < ActivityPub::Serializer
  serialize(:type) { 'Announce' }

  serialize :id, :actor, :object

  def id
    ActivityPub::TagManager.instance.activity_uri_for(model)
  end

  def actor
    ActivityPub::TagManager.instance.uri_for(model.account)
  end

  def object
    ActivityPub::TagManager.instance.uri_for(model.proper)
  end
end
