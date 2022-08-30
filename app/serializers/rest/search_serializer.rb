# frozen_string_literal: true

class REST::SearchSerializer < Blueprinter::Base
  association :accounts, blueprint: REST::AccountSerializer

  view :guest do
    association :hashtags, blueprint: REST::TagSerializer, view: :guest
    association :statuses, blueprint: REST::StatusSerializer, view: :guest
  end

  view :logged_in do
    association :hashtags, blueprint: REST::TagSerializer, view: :logged_in
    association :statuses, blueprint: REST::StatusSerializer, view: :logged_in
  end
end
