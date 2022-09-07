# frozen_string_literal: true

module InlineRenderer
  def self.render(object, current_account, template)
    case template
    when :status
      serializer = REST::StatusSerializer
    when :notification
      serializer = REST::NotificationSerializer
    when :conversation
      serializer = REST::ConversationSerializer
    when :announcement
      serializer = REST::AnnouncementSerializer
    when :reaction
      serializer = REST::ReactionSerializer
    when :encrypted_message
      return REST::EncryptedMessageSerializer.render_as_json(object)
    else
      return
    end

    if current_account.nil?
      return serializer.render_as_json(object, view: :guest)
    else
      return serializer.render_as_json(object, view: :logged_in, current_account: current_account)
    end
  end
end
