# frozen_string_literal: true

class REST::FeaturedTagSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  field :display_name, name: :name

  field :id do |object|
    object.id.to_s
  end

  field :url do |object|
    short_account_tag_url(object.account, object.tag)
  end

  field :statuses_count do |object|
    object.statuses_count.to_s
  end

  field :last_status_at do |object|
    object.last_status_at&.to_date&.iso8601
  end
end
