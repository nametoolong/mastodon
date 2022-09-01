# frozen_string_literal: true

class REST::FilterKeywordSerializer < Blueprinter::Base
  fields :keyword, :whole_word

  field :id do |object|
    object.id.to_s
  end
end
