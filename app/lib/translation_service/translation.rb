# frozen_string_literal: true

TranslationService::Translation = Struct.new(:text, :detected_source_language, :provider, keyword_init: true)
