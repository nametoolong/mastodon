# frozen_string_literal: true

class Webhooks::EventPresenter
  attr_reader :type, :created_at, :object

  def initialize(type, object)
    @type       = type
    @created_at = Time.now.utc
    @object     = object
  end
end
