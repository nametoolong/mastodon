# frozen_string_literal: true
# == Schema Information
#
# Table name: settings
#
#  id         :bigint(8)        not null, primary key
#  var        :string           not null
#  value      :text
#  thing_type :string
#  created_at :datetime
#  updated_at :datetime
#  thing_id   :bigint(8)
#

class Setting < RailsSettings::Base
  source Rails.root.join('config', 'settings.yml')

  def to_param
    var
  end

  class << self
    def [](key)
      return super(key) unless rails_initialized?

      val = Rails.cache.fetch(cache_key(key, nil)) do
        db_val = object(key)

        if db_val
          default_value = default_settings[key]

          return default_value.with_indifferent_access.merge!(db_val.value) if default_value.is_a?(Hash)
          db_val.value
        else
          default_settings[key]
        end
      end
      val
    end

    def get_multi(keys)
      return keys.index_with { |k| Setting[k] } unless rails_initialized?

      cache_keys = keys.to_h { |key| [Setting.cache_key(key, nil), key] }
      hits = Rails.cache.read_multi(*cache_keys.keys)
      default_values = default_settings

      fetched_values = {}

      cache_keys.each do |cache_key, key|
        next if hits.include?(cache_key)

        db_val = object(key)
        default_value = default_values[key]

        fetched_values[cache_key] = begin
          if db_val.nil?
            default_value
          elsif default_value.is_a?(Hash)
            default_value.with_indifferent_access.merge!(db_val.value)
          else
            db_val.value
          end
        end
      end

      hits.merge!(fetched_values)

      Rails.cache.write_multi(fetched_values)

      hits.transform_keys! { |cache_key| cache_keys[cache_key] }
    end

    def all_as_records
      vars    = thing_scoped
      records = vars.index_by(&:var)

      default_settings.each do |key, default_value|
        next if records.key?(key) || default_value.is_a?(Hash)
        records[key] = Setting.new(var: key, value: default_value)
      end

      records
    end

    def default_settings
      return {} unless RailsSettings::Default.enabled?
      RailsSettings::Default.instance
    end
  end
end
