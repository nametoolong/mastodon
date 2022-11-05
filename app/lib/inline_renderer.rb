# frozen_string_literal: true

module InlineRenderer
  def self.render(object, current_account, template)
    case template
    when :status
      serializer = REST::StatusSerializer
      preload_associations_for_status(object)
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
      serializer.render_as_json(object, view: :guest)
    else
      serializer.render_as_json(object, view: :logged_in, current_account: current_account)
    end
  end

  def self.preload_associations_for_status(object)
    ActiveRecord::Associations::Preloader.new.preload(object, {
      active_mentions: :account,

      reblog: {
        active_mentions: :account,
      },
    })
  end

  private_class_method :preload_associations_for_status
end
