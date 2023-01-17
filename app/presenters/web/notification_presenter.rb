# frozen_string_literal: true

class Web::NotificationPresenter
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper

  attr_reader :id, :type, :access_token, :preferred_locale

  def initialize(notification, subscription)
    @id = notification.id
    @type = notification.type

    @access_token = subscription.associated_access_token
    @preferred_locale = subscription.associated_user&.locale || I18n.default_locale

    @from_account = notification.from_account
    @target_status = notification.target_status
  end

  def body
    str = strip_tags(@target_status&.spoiler_text&.presence || @target_status&.text || @from_account.note)
    truncate(HTMLEntities.new.decode(str.to_str), length: 140, escape: false) # Do not encode entities, since this value will not be used in HTML
  end

  def title
    I18n.t("notification_mailer.#{type}.subject", name: @from_account.display_name.presence || @from_account.username)
  end

  def icon
    @from_account.avatar
  end
end
