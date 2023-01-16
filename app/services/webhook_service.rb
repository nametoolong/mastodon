# frozen_string_literal: true

class WebhookService < BaseService
  def call(event, object, webhooks)
    @event  = Webhooks::EventPresenter.new(event, object)
    @body   = serialize_event

    webhooks.each do |webhook_id|
      Webhooks::DeliveryWorker.perform_async(webhook_id, @body)
    end
  end

  private

  def serialize_event
    view = begin
      case @event.class.name
      when 'Account'
        :account
      when 'Report'
        :report
      end
    end

    REST::Admin::WebhookEventSerializer.render(@event, view: view)
  end
end
