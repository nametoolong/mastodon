# frozen_string_literal: true

class REST::Admin::CohortSerializer < Blueprinter::Base
  field :frequency

  field :period do |object|
    object.period.iso8601
  end

  class CohortDataSerializer < Blueprinter::Base
    fields :rate, :value

    field :date do |object|
      object.date.iso8601
    end
  end

  association :data, blueprint: CohortDataSerializer
end
