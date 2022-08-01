# frozen_string_literal: true

class PushEncryptedMessageWorker
  include Sidekiq::Worker
  include Redisable

  def perform(encrypted_message_id)
    encrypted_message = EncryptedMessage.find(encrypted_message_id)
    message           = InlineRenderer.render(encrypted_message, nil, :encrypted_message)
    timeline_id       = "timeline:#{encrypted_message.device.account_id}:#{encrypted_message.device.device_id}"
    payload = {
      event: :encrypted_message,
      payload: message,
      queued_at: (Time.now.to_f * 1000.0).to_i)
    }.to_bson.to_s

    redis.publish(timeline_id, payload)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
