# frozen_string_literal: true

class NodeInfo::DiscoverySerializer < Blueprinter::Base
  extend StaticRoutingHelper

  field :links do
    [{ rel: 'http://nodeinfo.diaspora.software/ns/schema/2.0', href: nodeinfo_schema_url }]
  end

  transform NodeInfo::Transformer
end
