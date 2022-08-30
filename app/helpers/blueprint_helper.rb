# frozen_string_literal: true

module BlueprintHelper
  def render_blueprint_with_account(klass, target, **kwargs)
    if current_account.nil?
      kwargs.merge!(view: :guest)
    else
      kwargs.merge!(view: :logged_in, current_account: current_account)
    end

    klass.render(target, **kwargs)
  end

  def render_as_json_with_account(klass, target, **kwargs)
    if current_user.nil?
      kwargs.merge!(view: :guest)
    else
      kwargs.merge!(view: :logged_in, current_account: current_user.account)
    end

    klass.render_as_json(target, **kwargs)
  end
end
