# frozen_string_literal: true

class REST::Admin::MeasureSerializer < Blueprinter::Base
  fields :key, :unit, :data

  field :total do |object|
    object.total.to_s
  end

  field :human_value, if: ->(_name, object, options) {
    object.respond_to?(:value_to_human_value)
  } do |object|
    object.value_to_human_value(object.total)
  end

  field :previous_total, if: ->(_name, object, options) {
    object.total_in_time_range?
  } do |object|
    object.previous_total.to_s
  end
end
