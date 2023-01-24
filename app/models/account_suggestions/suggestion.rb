# frozen_string_literal: true

AccountSuggestions::Suggestion = Struct.new(:account, :source, keyword_init: true) do
  delegate :id, to: :account, prefix: true
end
