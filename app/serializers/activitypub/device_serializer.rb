# frozen_string_literal: true

class ActivityPub::DeviceSerializer < ActivityPub::Serializer
  include RoutingHelper

  context_extension :olm

  serialize(:type) { 'Device' }

  serialize :name, :claim
  serialize :deviceId, from: :device_id

  nest_in :fingerprintKey do
    serialize(:type) { 'Ed25519Key' }

    serialize :publicKeyBase64, from: :fingerprint_key
  end

  nest_in :identityKey do
    serialize(:type) { 'Curve25519Key' }

    serialize :publicKeyBase64, from: :identity_key
  end

  def claim
    account_claim_url(model.account, id: model.device_id)
  end
end
