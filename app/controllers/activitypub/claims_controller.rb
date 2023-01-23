# frozen_string_literal: true

class ActivityPub::ClaimsController < ActivityPub::BaseController
  include SignatureVerification
  include AccountOwnedConcern

  skip_before_action :authenticate_user!

  before_action :require_account_signature!
  before_action :set_claim_result

  def create
    render json: ActivityPub::OneTimeKeySerializer.new(@claim_result).as_json
  end

  private

  def set_claim_result
    @claim_result = ::Keys::ClaimService.new.call(@account.id, params[:id])
  end
end
