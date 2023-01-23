# frozen_string_literal: true

class ActivityPub::OneTimeKeySerializer < ActivityPub::Serializer
  context :security
  context_extension :olm

  serialize(:type) { 'Curve25519Key' }

  serialize :keyId, from: :key_id
  serialize :publicKeyBase64, from: :key

  nest_in :signature do
    serialize(:type) { 'Ed25519Signature' }

    serialize :signatureValue, from: :signature
  end
end
