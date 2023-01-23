# frozen_string_literal: true

class ActivityPub::LikeSerializer < ActivityPub::Serializer
  serialize(:type) { 'Like' }

  serialize :id, :actor, :object

  def id
    [ActivityPub::TagManager.instance.uri_for(model.account), '#likes/', model.id].join
  end

  def actor
    ActivityPub::TagManager.instance.uri_for(model.account)
  end

  def object
    ActivityPub::TagManager.instance.uri_for(model.status)
  end
end
