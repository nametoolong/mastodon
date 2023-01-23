# frozen_string_literal: true

class ActivityPub::Serializer < CacheCrispies::Base
  class << self
    def named_contexts
      @named_contexts ||= {}
    end

    def context_extensions
      @context_extensions ||= {}
    end

    def context(*contexts)
      contexts.each do |context|
        named_contexts[context] = true
      end
    end

    def context_extension(*contexts)
      contexts.each do |context|
        context_extensions[context] = true
      end
    end

    def use_contexts_from(serializer)
      named_contexts.merge!(serializer.named_contexts)
      context_extensions.merge!(serializer.context_extensions)
    end

    def serialize(*args, **kwargs, &block)
      serializer = kwargs[:with]

      use_contexts_from(serializer) if serializer

      super(*args, **kwargs, &block)
    end
  end
end
