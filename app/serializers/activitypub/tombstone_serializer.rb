# frozen_string_literal: true

class ActivityPub::TombstoneSerializer < ActivityPub::Serializer
  context_extension :atom_uri

  serialize(:type) { 'Tombstone' }

  serialize :id
  serialize :atomUri, from: :atom_uri

  def id
    ActivityPub::TagManager.instance.uri_for(model)
  end

  def atom_uri
    OStatus::TagManager.instance.uri_for(model)
  end
end
