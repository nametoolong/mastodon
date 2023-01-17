# frozen_string_literal: true

class REST::TranslationSerializer < Blueprinter::Base
  fields :detected_source_language, :provider

  field :text:, name: :content
end
