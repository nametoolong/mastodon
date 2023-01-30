# frozen_string_literal: true

class REST::Admin::AccountSerializer < Blueprinter::Base
  fields :username, :domain, :created_at

  field :user_email, name: :email
  field :suspended?, name: :suspended
  field :silenced?, name: :silenced
  field :sensitized?, name: :sensitized
  field :user_confirmed?, name: :confirmed
  field :user_disabled?, name: :disabled
  field :user_approved?, name: :approved
  field :user_locale, name: :locale

  field :id do |object|
    object.id.to_s
  end

  field :ip do |object|
    object.user&.ips&.first&.ip
  end

  field :invite_request do |object|
    object.user&.invite_request&.text
  end

  field :created_by_application_id, if: ->(_name, object, options) {
    object.user&.created_by_application_id&.present?
  } do |object|
    object.user&.created_by_application_id&.to_s&.presence
  end

  field :invited_by_account_id, if: ->(_name, object, options) {
    object.user&.invited?
  } do |object|
    object.user&.invite&.user&.account_id&.to_s&.presence
  end

  association :itself, name: :account, blueprint: REST::AccountSerializer
  association :user_role, name: :role, blueprint: REST::RoleSerializer, view: :full
  association :ips, blueprint: REST::Admin::IpSerializer do |object|
    object.user&.ips
  end
end
