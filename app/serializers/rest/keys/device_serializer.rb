# frozen_string_literal: true

class REST::Keys::DeviceSerializer < Blueprinter::Base
  fields :device_id, :name, :identity_key,
         :fingerprint_key
end
