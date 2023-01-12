# frozen_string_literal: true

class TriggerWebhookWorker
  include Sidekiq::Worker

  def perform(event, class_name, id)
    webhooks = Webhook.enabled.where('? = ANY(events)', event).pluck(:id)

    return if webhooks.empty?

    object = class_name.constantize.find(id)
    WebhookService.new.call(event, object, webhooks)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
