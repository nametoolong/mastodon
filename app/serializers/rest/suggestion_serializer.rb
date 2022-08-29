# frozen_string_literal: true

class REST::SuggestionSerializer < Blueprinter::Base
  field :source

  association :account, blueprint: REST::AccountSerializer
end
