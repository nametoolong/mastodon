# frozen_string_literal: true

class ActivityPub::MoveSerializer < ActivityPub::Serializer
  serialize(:type) { 'Move' }

  serialize :id, :target, :actor, :object

  def id
    [ActivityPub::TagManager.instance.uri_for(model.account), '#moves/', model.id].join
  end

  def target
    ActivityPub::TagManager.instance.uri_for(model.target_account)
  end

  def actor
    ActivityPub::TagManager.instance.uri_for(model.account)
  end

  def object
    ActivityPub::TagManager.instance.uri_for(model.account)
  end
end
