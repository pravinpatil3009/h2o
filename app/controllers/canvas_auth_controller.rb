class CanvasAuthController < ApplicationController

  def authorize
    canvas_auth = CanvasAuth.new(request)

    if canvas_auth.valid?
      render :text => "AUTHORIZED"
    else
      render :text => "DENIED"
    end
  end

  def lti_config

  end
end
