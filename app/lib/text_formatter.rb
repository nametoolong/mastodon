# frozen_string_literal: true

class TextFormatter
  include ActionView::Helpers::TextHelper
  include ERB::Util
  include RoutingHelper
  include Singleton

  URL_PREFIX_REGEX = /\A(https?:\/\/(www\.)?|xmpp:)/.freeze

  DEFAULT_REL = 'nofollow noopener noreferrer'
  DEFAULT_ME_REL = 'nofollow noopener noreferrer me'

  # @param [String] text
  # @param [Hash] options
  # @option options [Boolean] :multiline
  # @option options [Boolean] :with_domains
  # @option options [Boolean] :with_rel_me
  # @option options [Array<Account>] :preloaded_accounts
  def format(text, options = {})
    return ''.html_safe if text.blank?

    link_rel = options[:with_rel_me] ? DEFAULT_ME_REL : DEFAULT_REL
    with_domains = options[:with_domains]
    preloaded_accounts = options[:preloaded_accounts]

    html = rewrite(text) do |entity|
      if entity[:url]
        link_to_url(entity, link_rel)
      elsif entity[:hashtag]
        link_to_hashtag(entity)
      elsif entity[:screen_name]
        link_to_mention(entity, with_domains, preloaded_accounts)
      end
    end

    html = simple_format(html, {}, sanitize: false).delete("\n") unless options[:multiline] == false

    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def rewrite(text)
    entities = Extractor.extract_entities_with_indices(text, extract_url_without_protocol: false)

    entities.sort_by! do |entity|
      entity[:indices].first
    end

    result = +""

    last_index = entities.reduce(0) do |index, entity|
      indices = entity[:indices]
      result << h(text[index...indices.first])
      result << yield(entity)
      indices.last
    end

    result << h(text[last_index..-1])

    result
  end

  def link_to_url(entity, link_rel)
    url = Addressable::URI.parse(entity[:url]).to_s

    prefix      = url.match(URL_PREFIX_REGEX).to_s
    display_url = url[prefix.length, 30]
    suffix      = url[prefix.length + 30..-1]
    cutoff      = url[prefix.length..-1].length > 30

    <<~HTML.squish
      <a href="#{h(url)}" target="_blank" rel="#{link_rel}"><span class="invisible">#{h(prefix)}</span><span class="#{cutoff ? 'ellipsis' : ''}">#{h(display_url)}</span><span class="invisible">#{h(suffix)}</span></a>
    HTML
  rescue Addressable::URI::InvalidURIError, IDN::Idna::IdnaError
    h(entity[:url])
  end

  def link_to_hashtag(entity)
    hashtag = entity[:hashtag]
    url     = tag_url(hashtag)

    <<~HTML.squish
      <a href="#{h(url)}" class="mention hashtag" rel="tag">#<span>#{h(hashtag)}</span></a>
    HTML
  end

  def link_to_mention(entity, with_domains, preloaded_accounts)
    username, domain = entity[:screen_name].split('@')
    domain           = nil if tag_manager.local_domain?(domain)
    account          = nil

    if preloaded_accounts.present?
      same_username_hits = 0

      preloaded_accounts.each do |other_account|
        same_username = other_account.username.casecmp(username).zero?
        same_domain   = other_account.domain.nil? ? domain.nil? : other_account.domain.casecmp(domain)&.zero?

        if same_username && !same_domain
          same_username_hits += 1
        elsif same_username && same_domain
          account = other_account
        end
      end
    else
      account = entity_cache.mention(username, domain)
    end

    return "@#{h(entity[:screen_name])}" if account.nil?

    url = ActivityPub::TagManager.instance.url_for(account)
    display_username = same_username_hits&.positive? || with_domains ? account.pretty_acct : account.username

    <<~HTML.squish
      <span class="h-card"><a href="#{h(url)}" class="u-url mention">@<span>#{h(display_username)}</span></a></span>
    HTML
  end

  def entity_cache
    @entity_cache ||= EntityCache.instance
  end

  def tag_manager
    @tag_manager ||= TagManager.instance
  end
end
