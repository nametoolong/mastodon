# frozen_string_literal: true

class REST::MarkerSerializer < Blueprinter::Base
  field :updated_at

  field :lock_version, name: :version

  field :last_read_id do |object|
    object.last_read_id.to_s
  end
end
