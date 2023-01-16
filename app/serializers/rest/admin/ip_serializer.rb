# frozen_string_literal: true

class REST::Admin::IpSerializer < Blueprinter::Base
  fields :ip, :used_at
end
