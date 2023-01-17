# frozen_string_literal: true

class REST::PreferencesSerializer < Blueprinter::Base
  field 'posting:default:visibility' do |object|
    object.user.setting_default_privacy
  end

  field 'posting:default:sensitive' do |object|
    object.user.setting_default_sensitive
  end

  field 'posting:default:language' do |object|
    object.user.preferred_posting_language
  end

  field 'reading:expand:media' do |object|
    object.user.setting_display_media
  end

  field 'reading:expand:spoilers' do |object|
    object.user.setting_expand_spoilers
  end

  field 'reading:autoplay:gifs' do |object|
    object.user.setting_auto_play_gif
  end
end
