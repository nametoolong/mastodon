# frozen_string_literal: true

class REST::FilterSerializer < Blueprinter::Base
  fields :title, :context, :expires_at, :filter_action

  field :id do |object|
    object.id.to_s
  end

  association :keywords, if: -> (_name, object, options) {
    options[:rules_requested]
  }, blueprint: REST::FilterKeywordSerializer

  association :statuses, if: -> (_name, object, options) {
    options[:rules_requested]
  }, blueprint: REST::FilterStatusSerializer
end
