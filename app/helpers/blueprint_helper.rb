# frozen_string_literal: true

module BlueprintHelper
  def render_blueprint_with_account(klass, target, **kwargs)
    kwargs.merge!(blueprint_options_by_account)
    klass.render(target, **kwargs)
  end

  def render_as_json_with_account(klass, target, **kwargs)
    kwargs.merge!(blueprint_options_by_account)
    klass.render_as_json(target, **kwargs)
  end

  private

  def blueprint_options_by_account
    if current_account.nil?
      {view: :guest}
    else
      {view: :logged_in, current_account: current_account}
    end
  end
end
