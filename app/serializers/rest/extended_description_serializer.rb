# frozen_string_literal: true

class REST::ExtendedDescriptionSerializer < Blueprinter::Base
  field :updated_at

  field :content do |object|
    if object.text.present?
      Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(object.text)
    else
      ''
    end
  end
end
