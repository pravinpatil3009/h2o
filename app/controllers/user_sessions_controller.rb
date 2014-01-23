class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
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
        save_canvas_id_to_current_user if first_time_canvas_login?
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

  def first_time_canvas_login?
    session.key?(:canvas_user_id)
  end

  def save_canvas_id_to_current_user
    @user_session.user.update_attribute(:canvas_id, session.fetch(:canvas_user_id))
    clear_canvas_id_from_session
  end

  def clear_canvas_id_from_session
    session[:canvas_user_id] = nil
  end


end
