require_relative '../../lib/premailer/adapter/nokolexbor'
require_relative '../../lib/premailer/lexbor_patch'
require_relative '../../lib/premailer/rails_patch'
require_relative '../../lib/mastodon/premailer_webpack_strategy'

Premailer::Rails.config.merge!(remove_ids: true,
                               adapter: Premailer::Adapter::Nokolexbor,
                               generate_text_part: false,
                               strategies: [PremailerWebpackStrategy])
