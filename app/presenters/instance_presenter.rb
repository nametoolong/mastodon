# frozen_string_literal: true

class InstancePresenter
  delegate(
    :site_contact_email,
    :site_title,
    :site_short_description,
    :site_description,
    :site_extended_description,
    :site_terms,
    :closed_registrations_message,
    to: Setting
  )

  def contact_account
    Account.find_local(Setting.site_contact_username.strip.gsub(/\A@/, ''))
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

  def sample_account_avatars
    Rails.cache.fetch('sample_account_avatars', expires_in: 12.hours) do
      popular_accounts = Account.local.discoverable.popular
      popular_accounts.limit(3).map do |acct|
        {
          avatar_original_url: acct.avatar_original_url,
          avatar_static_url: acct.avatar_static_url,
        }
      end
    end
  end

  def version_number
    Mastodon::Version
  end

  def source_url
    Mastodon::Version.source_url
  end

  def thumbnail
    @thumbnail ||= Rails.cache.fetch('site_uploads/thumbnail') { SiteUpload.find_by(var: 'thumbnail') }
  end

  def hero
    @hero ||= Rails.cache.fetch('site_uploads/hero') { SiteUpload.find_by(var: 'hero') }
  end

  def mascot
    @mascot ||= Rails.cache.fetch('site_uploads/mascot') { SiteUpload.find_by(var: 'mascot') }
  end
end
