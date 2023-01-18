# frozen_string_literal: true

class NodeInfo::Transformer < Blueprinter::Transformer
  @@node_info_key_cache = {}

  def transform(hash, _object, _options)
    hash.deep_transform_keys! do |key|
      @@node_info_key_cache[key] ||= key.to_s.camelize(:lower)
    end
  end
end
