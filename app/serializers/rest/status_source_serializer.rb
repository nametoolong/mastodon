# frozen_string_literal: true

class REST::StatusSourceSerializer < Blueprinter::Base
  fields :text, :spoiler_text

  field :id do |object|
    object.id.to_s
  end
end
