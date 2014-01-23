class CanvasAuthController < ApplicationController

  def authorize
    #canvas_auth = CanvasAuth.new(request)

    #if canvas_auth.valid?
    #lookup_user
    #if user
    #login_user
    #redirect_to_dashboard
    #else
    set_flash_message
    set_session_with_canvas_user_id
    redirect_to_h2o_login
    #end
    #flash[:notice] = 'ladi dadi'
    #session[:canvas_user_id] = '02c18b8291c5f3b1ac400184c3882698bb66ca9e'#params.fetch(:user_id)
    #redirect_to new_user_session_path
      #render :text => "AUTHORIZED"
    #else
      #render 'unauthorized'
    #end
  end

  def set_session_with_canvas_user_id
    session[:canvas_user_id] = '02c18b8291c5f3b1ac400184c3882698bb66ca9e'#params.fetch(:user_id)
  end

  def redirect_to_h2o_login
    redirect_to new_user_session_path
  end

  def set_flash_message
    flash[:notice] =
    "You are logging in to H2o directly from Canvas for the first time.<br/><br/>
     After you login your Canvas id will be attached to your H2o id
     and the next time you initiate an H2o session from Canvas you'll be logged in
     automatically.".html_safe
  end

  def lti_config

  end
end
