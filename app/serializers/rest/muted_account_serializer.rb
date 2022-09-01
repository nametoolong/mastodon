# frozen_string_literal: true

class REST::MutedAccountSerializer < REST::AccountSerializer
  field :mute_expires_at do |object, options|
    mute = options[:mutes][object.id]
    mute && !mute.expired? ? mute.expires_at : nil
  end
end
