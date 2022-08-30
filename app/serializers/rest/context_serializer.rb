# frozen_string_literal: true

class REST::ContextSerializer < Blueprinter::Base
  view :guest do
    association :ancestors, blueprint: REST::StatusSerializer, view: :guest
    association :descendants, blueprint: REST::StatusSerializer, view: :guest
  end

  view :logged_in do
    association :ancestors, blueprint: REST::StatusSerializer, view: :logged_in
    association :descendants, blueprint: REST::StatusSerializer, view: :logged_in
  end
end
