# frozen_string_literal: true

class ActivityPub::StatusUpdateDistributionWorker < ActivityPub::DistributionWorker
  # Distribute an profile update to servers that might have a copy
  # of the account in question
  def perform(status_id, options = {})
    @options = options.with_indifferent_access
    @status  = Status.find(status_id)
    @account = @status.account

    distribute!
  rescue ActiveRecord::RecordNotFound
    true
  end

  protected

  def payload
    @payload ||= Oj.dump(ActivityPub::Renderer.new(:update_note, @status).render(signer: @account))
  end
end
