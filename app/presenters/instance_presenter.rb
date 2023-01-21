# frozen_string_literal: true

class InstancePresenter < SitePresenter
  SETTING_KEYS = %w(
    closed_registrations_message
    site_contact_email
    site_contact_username
    site_short_description
  ).freeze

  ContactPresenter = Struct.new(:email, :account)

  def contact
    @contact ||= begin
      username, domain = site_settings[:site_contact_username].strip.gsub(/\A@/, '').split('@', 2)
      domain = nil if TagManager.instance.local_domain?(domain)
      account = Account.find_remote(username, domain) if username.present?

      ContactPresenter.new(site_settings[:site_contact_email], account)
    end
  end

  def closed_registrations_message
    site_settings[:closed_registrations_message]
  end

  def description
    site_settings[:site_short_description]
  end

  def languages
    [I18n.default_locale]
  end

  def rules
    Rule.ordered
  end

  class << self
    def setting_keys
      @setting_keys ||= super + SETTING_KEYS
    end
  end
end
