# frozen_string_literal: true

module Settings
  class ScopedSettings
    def initialize(object)
      @object = object
    end

    def method_missing(method, *args)
      method_name = method.to_s
      # set a value for a variable
      if method_name[-1] == '='
        var_name = method_name.sub('=', '')
        value = args.first
        self[var_name] = value
      else
        # retrieve a value
        self[method_name]
      end
    end

    def respond_to_missing?(*)
      true
    end

    def all_as_records
      vars = thing_scoped
      records = vars.index_by(&:var)

      Setting.default_settings.each do |key, default_value|
        next if records.key?(key) || default_value.is_a?(Hash)
        records[key] = Setting.new(var: key, value: default_value)
      end

      records
    end

    def []=(key, value)
      key = key.to_s
      record = thing_scoped.find_or_initialize_by(var: key)
      record.update!(value: value)

      Rails.cache.write(Setting.cache_key(key, @object), value)
    end

    def [](key)
      Rails.cache.fetch(Setting.cache_key(key, @object)) do
        db_val = thing_scoped.find_by(var: key.to_s)
        if db_val
          default_value = DefaultSettings[key]
          return default_value.with_indifferent_access.merge!(db_val.value) if default_value.is_a?(Hash)
          db_val.value
        else
          DefaultSettings[key]
        end
      end
    end

    def get_multi(keys)
      cache_keys = keys.to_h { |key| [Setting.cache_key(key, @object), key] }
      hits = Rails.cache.read_multi(*cache_keys.keys).transform_keys! { |key| cache_keys[key] }
      to_fetch = keys - hits.keys

      if to_fetch
        db_values = thing_scoped.where(var: to_fetch).select(:var, :value).index_by(&:var)
        missing_keys = to_fetch - db_values.keys
        default_values = DefaultSettings.get_multi(to_fetch)

        fetched_values = missing_keys.to_h { |key| [key, default_values[key]] }

        db_values.each do |key, db_val|
          default_value = default_values[key]

          fetched_values[key] = begin
            if default_value.is_a?(Hash)
              default_value.with_indifferent_access.merge!(db_val.value)
            else
              db_val.value
            end
          end
        end

        hits.merge!(fetched_values)

        fetched_values.transform_keys! { |key| Setting.cache_key(key, @object) }

        Rails.cache.write_multi(fetched_values) unless fetched_values.empty?
      end

      hits
    end

    module DefaultSettings
      DEFAULTING_TO_UNSCOPED = %w(
        theme
        noindex
      ).freeze

      class << self
        def [](key)
          if DEFAULTING_TO_UNSCOPED.include?(key)
            Setting[key]
          else
            Setting.default_settings[key]
          end
        end

        def get_multi(keys)
          unscoped_keys = keys & DEFAULTING_TO_UNSCOPED
          Setting.default_settings.merge!(Setting.get_multi(unscoped_keys)) unless unscoped_keys.empty?
          Setting.default_settings
        end
      end
    end

    protected

    def thing_scoped
      Setting.unscoped.where(thing_type: @object.class.base_class.to_s, thing_id: @object.id)
    end
  end
end
