# frozen_string_literal: true

class WebfingerSerializer < Blueprinter::Base
  extend StaticRoutingHelper

  field :to_webfinger_s, name: :subject

  field :aliases do |object|
    if object.instance_actor?
      [instance_actor_url]
    else
      [short_account_url(object), account_url(object)]
    end
  end

  field :links do |object|
    if object.instance_actor?
      [
        { rel: 'http://webfinger.net/rel/profile-page', type: 'text/html', href: about_more_url(instance_actor: true) },
        { rel: 'self', type: 'application/activity+json', href: instance_actor_url },
      ]
    else
      [
        { rel: 'http://webfinger.net/rel/profile-page', type: 'text/html', href: short_account_url(object) },
        { rel: 'self', type: 'application/activity+json', href: account_url(object) },
        { rel: 'http://ostatus.org/schema/1.0/subscribe', template: "#{authorize_interaction_url}?uri={uri}" },
      ]
    end
  end
end
