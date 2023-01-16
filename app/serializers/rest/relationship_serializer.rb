# frozen_string_literal: true

class REST::RelationshipSerializer < Blueprinter::Base
  field :id do |object|
    object.id.to_s
  end

  field :following do |object, options|
    options[:relationships].following[object.id] ? true : false
  end

  field :showing_reblogs do |object, options|
    (options[:relationships].following[object.id] || {})[:reblogs] ||
      (options[:relationships].requested[object.id] || {})[:reblogs] ||
      false
  end

  field :notifying do |object, options|
    (options[:relationships].following[object.id] || {})[:notify] ||
      (options[:relationships].requested[object.id] || {})[:notify] ||
      false
  end

  field :languages do |object, options|
    (options[:relationships].following[object.id] || {})[:languages] ||
      (options[:relationships].requested[object.id] || {})[:languages]
  end

  field :followed_by do |object, options|
    options[:relationships].followed_by[object.id] || false
  end

  field :blocking do |object, options|
    options[:relationships].blocking[object.id] || false
  end

  field :blocked_by do |object, options|
    options[:relationships].blocked_by[object.id] || false
  end

  field :muting do |object, options|
    options[:relationships].muting[object.id] ? true : false
  end

  field :muting_notifications do |object, options|
    (options[:relationships].muting[object.id] || {})[:notifications] || false
  end

  field :requested do |object, options|
    options[:relationships].requested[object.id] ? true : false
  end

  field :requested_by do |object, options|
    options[:relationships].requested_by[object.id] ? true : false
  end

  field :domain_blocking do |object, options|
    options[:relationships].domain_blocking[object.id] || false
  end

  field :endorsed do |object, options|
    options[:relationships].endorsed[object.id] || false
  end

  field :note do |object, options|
    (options[:relationships].account_note[object.id] || {})[:comment] || ''
  end
end
