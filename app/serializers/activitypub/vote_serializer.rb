# frozen_string_literal: true

class ActivityPub::VoteSerializer < ActivityPub::Serializer
  serialize(:type) { 'Note' }

  serialize :id, :name, :to
  serialize :attributedTo, from: :attributed_to
  serialize :inReplyTo, from: :in_reply_to

  def id
    ActivityPub::TagManager.instance.uri_for(model) || [ActivityPub::TagManager.instance.uri_for(model.account), '#votes/', model.id].join
  end

  def name
    model.poll.options[model.choice.to_i]
  end

  def to
    ActivityPub::TagManager.instance.uri_for(model.poll.account)
  end

  def attributed_to
    ActivityPub::TagManager.instance.uri_for(model.account)
  end

  def in_reply_to
    ActivityPub::TagManager.instance.uri_for(model.poll.status)
  end
end
