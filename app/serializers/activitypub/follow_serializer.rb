# frozen_string_literal: true

class ActivityPub::FollowSerializer < ActivityPub::Serializer
  serialize(:type) { 'Follow' }

  serialize :id, :actor, :object

  def id
    ActivityPub::TagManager.instance.uri_for(model) || [ActivityPub::TagManager.instance.uri_for(model.account), '#follows/', model.id].join
  end

  def actor
    ActivityPub::TagManager.instance.uri_for(model.account)
  end

  def object
    ActivityPub::TagManager.instance.uri_for(model.target_account)
  end
end
