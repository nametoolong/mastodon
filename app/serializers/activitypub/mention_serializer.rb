# frozen_string_literal: true

class ActivityPub::MentionSerializer < ActivityPub::Serializer
  serialize(:type) { 'Mention' }

  serialize :name, :href

  def name
    "@#{model.account.acct}"
  end

  def href
    ActivityPub::TagManager.instance.uri_for(model.account)
  end
end
