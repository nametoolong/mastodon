# frozen_string_literal: true

class ActivityPub::HashtagSerializer < ActivityPub::Serializer
  include RoutingHelper

  context_extension :hashtag

  serialize(:type) { 'Hashtag' }

  serialize :name, :href

  def name
    "##{model.display_name}"
  end

  def href
    if model.instance_of?(FeaturedTag)
      short_account_tag_url(model.account, model.tag)
    else
      tag_url(model)
    end
  end
end
