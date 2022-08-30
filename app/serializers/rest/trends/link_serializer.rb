# frozen_string_literal: true

class REST::Trends::LinkSerializer < REST::PreviewCardSerializer
  field :history do |object|
    object.history.as_json
  end
end
