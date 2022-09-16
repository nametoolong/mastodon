# frozen_string_literal: true

module HtmlAwareFormatter
  def self.format(text, local, options = {})
    return ''.html_safe if text.blank?

    if local
      linkify(text, options)
    else
      reformat(text).html_safe # rubocop:disable Rails/OutputSafety
    end
  rescue ArgumentError
    ''.html_safe
  end

  def self.reformat(text)
    Sanitize.fragment(text, Sanitize::Config::MASTODON_STRICT)
  end

  def self.linkify(text, options)
    TextFormatter.instance.format(text, options)
  end

  private_class_method :reformat, :linkify
end
