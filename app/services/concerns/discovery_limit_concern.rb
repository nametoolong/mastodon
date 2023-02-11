# frozen_string_literal: true

module DiscoveryLimitConcern
  include Redisable

  DISCOVERIES_PER_REQUEST = 1000

  def request_id_from_uri(uri)
    digest = Digest::SHA256.base64digest(uri).slice!(0, 10)

    "#{Time.now.utc.to_i}-#{digest}"
  end

  def check_rate_limit!(request_id)
    discoveries = nil

    with_redis do |redis|
      yield redis if block_given?

      discoveries = redis.pipelined do |pipeline|
        pipeline.incr("discovery_per_request:#{request_id}")
        pipeline.expire("discovery_per_request:#{request_id}", 5.minutes.seconds)
      end.first
    end

    raise Mastodon::RateLimitExceededError if discoveries > DISCOVERIES_PER_REQUEST
  end
end
