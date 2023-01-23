# frozen_string_literal: true

class ActivityPub::PublicKeySerializer < ActivityPub::Serializer
  context :security

  serialize :id, :owner
  serialize :publicKeyPem, from: :public_key

  def id
    ActivityPub::TagManager.instance.key_uri_for(model)
  end

  def owner
    ActivityPub::TagManager.instance.uri_for(model)
  end
end
