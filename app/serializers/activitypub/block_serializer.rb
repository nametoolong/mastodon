# frozen_string_literal: true

class ActivityPub::BlockSerializer < ActivityPub::Serializer
  serialize(:type) { 'Block' }

  serialize :id, :actor, :object

  def id
    ActivityPub::TagManager.instance.uri_for(model) || [ActivityPub::TagManager.instance.uri_for(model.account), '#blocks/', model.id].join
  end

  def actor
    ActivityPub::TagManager.instance.uri_for(model.account)
  end

  def object
    ActivityPub::TagManager.instance.uri_for(model.target_account)
  end
end
