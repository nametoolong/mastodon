# frozen_string_literal: true

class ActivityPub::Parser::AudienceParser
  include JsonLdHelper

  def initialize(to:, cc:, followers:)
    @audience_to = Set.new(as_array(to).lazy.map { |x| value_or_id(x) })
    @audience_cc = Set.new(as_array(cc).lazy.map { |x| value_or_id(x) })
    @followers = followers
  end

  def audience_to
    @audience_to
  end

  def audience_cc
    @audience_cc
  end

  def visibility
    if has_public_collection?(audience_to)
      :public
    elsif has_public_collection?(audience_cc)
      :unlisted
    elsif audience_to.include?(@followers)
      :private
    else
      :direct
    end
  end

  private

  def has_public_collection?(audience)
    ActivityPub::TagManager::URIS_FOR_PUBLIC_COLLECTION.any? { |x| audience.include?(x) }
  end
end
