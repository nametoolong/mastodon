# frozen_string_literal: true

class InstancePresenter
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

  def registrations_mode
    site_settings[:registrations_mode]
  end

  def description
    site_settings[:site_short_description]
  end

  def extended_description
    site_settings[:site_extended_description]
  end

  def privacy_policy
    site_settings[:site_terms]
  end

  def domain
    Rails.configuration.x.local_domain
  end

  def title
    site_settings[:site_title]
  end

  def languages
    [I18n.default_locale]
  end

  def rules
    Rule.ordered
  end

  def user_count
    Rails.cache.fetch('user_count') { User.confirmed.joins(:account).merge(Account.without_suspended).count }
  end

  def active_user_count(num_weeks = 4)
    Rails.cache.fetch("active_user_count/#{num_weeks}") { ActivityTracker.new('activity:logins', :unique).sum(num_weeks.weeks.ago) }
  end

  def status_count
    Rails.cache.fetch('local_status_count') { Account.local.joins(:account_stat).sum('account_stats.statuses_count') }.to_i
  end

  def domain_count
    Rails.cache.fetch('distinct_domain_count') { Instance.count }
  end

  def version
    Mastodon::Version.to_s
  end

  def source_url
    Mastodon::Version.source_url
  end

  def thumbnail
    @thumbnail ||= Rails.cache.fetch('site_uploads/thumbnail') { SiteUpload.find_by(var: 'thumbnail') }
  end

  def mascot
    @mascot ||= Rails.cache.fetch('site_uploads/mascot') { SiteUpload.find_by(var: 'mascot') }
  end

  private

  def site_settings
    @site_settings ||= Setting.get_multi(%w(
      closed_registrations_message
      registrations_mode
      site_short_description
      site_extended_description
      site_terms
      site_title
      site_contact_email
      site_contact_username
    )).symbolize_keys!
  end
end
