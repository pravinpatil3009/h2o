class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  before_filter :display_first_time_canvas_notice, :only => [:new]
  protect_from_forgery :except => [:create]

  def new
    @user_session = UserSession.new
    render :layout => (request.xhr?) ? false : true
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|
      if result
        apply_user_preferences(@user_session.user)
        if first_time_canvas_login?
          save_canvas_id_to_user(@user_session.user)
          flash[:notice] = "You canvas id was attached to this account"
        end
        if request.xhr?
          #Text doesn't matter, status code does.
          render :text => 'Success!', :layout => false
        else
          redirect_back_or_default "/"
        end
      else
        render :action => :new, :layout => (request.xhr?) ? false : true, :status => :unprocessable_entity
      end
    end
  end

  def destroy
    destroy_user_preferences(current_user)
    current_user_session.destroy
    redirect_back_or_default "/"
  end

end
