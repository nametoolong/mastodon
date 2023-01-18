# frozen_string_literal: true

class SitePresenter
  SETTING_KEYS = %w(
    registrations_mode
    site_title
  ).freeze

  def domain
    Rails.configuration.x.local_domain
  end

  def title
    site_settings[:site_title]
  end

  def registrations_mode
    site_settings[:registrations_mode]
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

  def setting_keys
    SETTING_KEYS
  end

  def site_settings
    @site_settings ||= Setting.get_multi(setting_keys).symbolize_keys!
  end
end
