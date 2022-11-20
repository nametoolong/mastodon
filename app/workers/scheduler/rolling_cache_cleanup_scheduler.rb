# frozen_string_literal: true

class Scheduler:RollingCacheCleanupScheduler
  include Sidekiq::Worker

  CACHE_EXPIRATION_TIME = 5.minutes
  CACHE_KEYS = ["mastoduck:delivery", "mastoduck:fanout"]

  sidekiq_options retry: 0

  def perform
    CACHE_KEYS.each do |key|
      RollingCache.new(key).trim(CACHE_EXPIRATION_TIME)
    end
  end
end
