# frozen_string_literal: true

class REST::CredentialAccountSerializer < REST::AccountSerializer
  field :source do |object|
    user = object.user

    {
      privacy: user.setting_default_privacy,
      sensitive: user.setting_default_sensitive,
      language: user.setting_default_language,
      note: object.note,
      fields: object.fields.map(&:to_h),
      follow_requests_count: FollowRequest.where(target_account: object).limit(40).count,
    }
  end

  association :role, blueprint: REST::RoleSerializer do |object|
    object.user_role
  end
end
