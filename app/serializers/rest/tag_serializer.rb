# frozen_string_literal: true

class REST::TagSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  field :display_name, name: :name

  field :url do |object|
    tag_url(object)
  end

  field :history do |object|
    object.history.as_json
  end

  view :guest do
  end

  view :logged_in do
    field :following do |object, options|
      if options[:relationships]
        options[:relationships].following_map[object.id] || false
      else
        TagFollow.where(tag_id: object.id, account_id: options[:current_account].id).exists?
      end
    end
  end
end
