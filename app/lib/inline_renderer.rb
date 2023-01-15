# frozen_string_literal: true

module InlineRenderer
  def self.render(object, current_account, template)
    serializer = select_serializer(template)

    options = begin
      if template == :encrypted_message
        {}
      elsif current_account.nil?
        { view: :guest }
      else
        { view: :logged_in, current_account: current_account }
      end
    end

    if template == :status
      preload_associations_for_status(object)

      settings = object.account.user&.settings

      if settings
        options.merge!(settings: settings.get_multi(%w(noindex show_application)).symbolize_keys!)
      end
    end

    serializer.render_as_hash(object, **options)
  end

  def self.select_serializer(template)
    @serializer_map ||= {
      status: REST::StatusSerializer,
      notification: REST::NotificationSerializer,
      conversation: REST::ConversationSerializer,
      announcement: REST::AnnouncementSerializer,
      reaction: REST::ReactionSerializer,
      encrypted_message: REST::EncryptedMessageSerializer
    }

    @serializer_map[template]
  end

  def self.preload_associations_for_status(object)
    ActiveRecord::Associations::Preloader.new.preload(object, [
      :status_stat,
      :tags,
      account: [
        :account_stat,
        :user
      ],
      active_mentions: :account,
      reblog: {
        active_mentions: :account,
      },
    ])
  end

  private_class_method :select_serializer, :preload_associations_for_status
end
