# frozen_string_literal: true

class ActivityPub::EncryptedMessageSerializer < ActivityPub::Serializer
  context :security
  context_extension :olm

  serialize(:type) { 'EncryptedMessage' }

  serialize :cipherText, from: :body
  serialize :messageType, from: :type
  serialize :messageFranking, from: :message_franking

  nest_in :digest do
    serialize(:type) { 'Digest' }

    serialize :digestValue, from: :digest

    serialize :digestAlgorithm do
      'http://www.w3.org/2000/09/xmldsig#hmac-sha256'
    end
  end

  nest_in :attributedTo do
    serialize(:type) { 'Device' }

    serialize :deviceId, from: :device_id, through: :source_device
  end

  nest_in :to do
    serialize(:type) { 'Device' }

    serialize :deviceId, from: :target_device_id
  end
end
