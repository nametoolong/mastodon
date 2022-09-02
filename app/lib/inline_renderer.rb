# frozen_string_literal: true

class InlineRenderer
  include BlueprintHelper

  def initialize(object, current_account, template)
    @object          = object
    @current_account = current_account
    @template        = template
  end

  def render
    case @template
    when :status
      return render_as_json_with_account(REST::StatusSerializer, @object)
    when :notification
      return render_as_json_with_account(REST::NotificationSerializer, @object)
    when :conversation
      return render_as_json_with_account(REST::ConversationSerializer, @object)
    when :announcement
      serializer = REST::AnnouncementSerializer
    when :reaction
      serializer = REST::ReactionSerializer
    when :encrypted_message
      serializer = REST::EncryptedMessageSerializer
    else
      return
    end

    serializable_resource = ActiveModelSerializers::SerializableResource.new(@object, serializer: serializer, scope: current_user, scope_name: :current_user)
    serializable_resource.as_json
  end

  def self.render(object, current_account, template)
    new(object, current_account, template).render
  end

  private

  def current_user
    @current_account&.user
  end
end
