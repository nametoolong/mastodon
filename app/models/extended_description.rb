# frozen_string_literal: true

class ExtendedDescription < Struct.new(:text, :updated_at, keyword_init: true)
  def self.current
    custom = Setting.find_by(var: 'site_extended_description')

    if custom&.value.present?
      new(text: custom.value, updated_at: custom.updated_at)
    else
      new
    end
  end
end
