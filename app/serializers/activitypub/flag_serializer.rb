# frozen_string_literal: true

class ActivityPub::FlagSerializer < ActivityPub::Serializer
  serialize(:type) { 'Flag' }

  serialize :id, :actor, :content, :object

  def id
    ActivityPub::TagManager.instance.uri_for(model)
  end

  def actor
    ActivityPub::TagManager.instance.uri_for(options[:account] || model.account)
  end

  def content
    model.comment
  end

  def object
    [ActivityPub::TagManager.instance.uri_for(model.target_account)].concat(
      model.statuses.map { |status| ActivityPub::TagManager.instance.uri_for(status) }
    )
  end
end
