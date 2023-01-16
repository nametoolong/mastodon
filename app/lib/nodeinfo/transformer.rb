# frozen_string_literal: true

class NodeInfo::Transformer < Blueprinter::Transformer
  def transform(hash, _object, _options)
    CaseTransform.camel_lower(hash)
  end
end
