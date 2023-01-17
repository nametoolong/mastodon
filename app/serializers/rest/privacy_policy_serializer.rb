# frozen_string_literal: true

class REST::PrivacyPolicySerializer < Blueprinter::Base
  field :updated_at

  field :content do |object|
    Redcarpet::Markdown.new(Redcarpet::Render::HTML, escape_html: true, no_images: true).render(object.text % { domain: Rails.configuration.x.local_domain })
  end
end
