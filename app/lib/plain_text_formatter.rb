# frozen_string_literal: true

module PlainTextFormatter
  NEWLINE_TAGS_RE = /(<br \/>|<br>|<\/p>)+/.freeze

  def self.format(text, local)
    return text if local
    sanitizer.sanitize(insert_newlines(text)).chomp
  end

  private

  def self.insert_newlines(text)
    text.gsub(NEWLINE_TAGS_RE) { |match| "#{match}\n" }
  end

  def self.sanitizer
    @sanitizer ||= Rails::Html::FullSanitizer.new
  end
end
