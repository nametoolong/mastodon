# frozen_string_literal: true

class REST::PollSerializer < Blueprinter::Base
  fields :multiple, :votes_count, :voters_count

  field :id do |object|
    object.id.to_s
  end

  field :expires_at do |object|
    object.expires_at&.iso8601
  end

  field :expired do |object|
    object.expired?
  end

  field :options do |object|
    object.loaded_options.map do |option|
      {title: option.title, votes_count: option.votes_count}
    end
  end

  association :emojis, blueprint: REST::CustomEmojiSerializer

  view :guest do
  end

  view :logged_in do
    field :voted do |object, options|
      object.voted?(options[:current_account])
    end

    field :own_votes do |object, options|
      object.own_votes(options[:current_account])
    end
  end
end
