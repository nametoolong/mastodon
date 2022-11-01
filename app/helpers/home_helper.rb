# frozen_string_literal: true

module HomeHelper
  def default_props
    {
      locale: I18n.locale,
    }
  end

  def account_link_to(account, button = '', path: nil)
    def missing_account_section
      content_tag(:div,
                  content_tag(:div,
                              image_tag(full_asset_url('avatars/original/missing.png', skip_pipeline: true),
                                        class: 'account__avatar'),
                              class: 'account__avatar-wrapper') <<
                  content_tag(:span,
                              content_tag(:strong,
                                          t('about.contact_missing')) <<
                              content_tag(:span,
                                          t('about.contact_unavailable'),
                                          class: 'display-name__account'),
                              class: 'display-name'),
                  class: 'account__display-name')
    end

    def account_section(account)
      content_tag(:div,
                  image_tag(full_asset_url(current_account&.user&.setting_auto_play_gif ? account.avatar_original_url : account.avatar_static_url),
                            class: 'account__avatar', width: 46, height: 46),
                  class: 'account__avatar-wrapper') <<
      content_tag(:span,
                  content_tag(:bdi,
                              content_tag(:strong,
                                          display_name(account, custom_emojify: true),
                                          class: 'display-name__html emojify')) <<
                  content_tag(:span,
                              "@#{account.acct}",
                              class: 'display-name__account'),
                  class: 'display-name')
    end

    content_tag(:div, class: 'account') do
      content_tag(:div, class: 'account__wrapper') do
        section = if account.nil?
                    missing_account_section
                  else
                    link_to(account_section(account), path || ActivityPub::TagManager.instance.url_for(account), class: 'account__display-name')
                  end

        section + button
      end
    end
  end

  def obscured_counter(count)
    if count <= 0
      0
    elsif count == 1
      1
    else
      '1+'
    end
  end

  def custom_field_classes(field)
    if field.verified?
      'verified'
    else
      'emojify'
    end
  end

  def sign_up_message
    if closed_registrations?
      t('auth.registration_closed', instance: site_hostname)
    elsif open_registrations?
      t('auth.register')
    elsif approved_registrations?
      t('auth.apply_for_account')
    end
  end
end
