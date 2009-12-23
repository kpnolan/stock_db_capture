# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

#  helper :all (No! only this and the designatied controller, help you!)

  before_filter :authenticate

  layout proc{ |c| c.request.xhr? ? false : 'application' }

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store

  protect_from_forgery # :secret => '318f6277207e2f66424aae352e4b3a01'
  protect_from_forgery :only => [:create, :update, :destroy]

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

  protected

  def authorize
#    if request.class.to_s == "ActionController::TestRequest"
#      self.set_current_user(User.find(9))
#      self.set_current_timesheet(Timesheet.find(2))
#    end
    case
    when session_stale? then
      self.current_session = nil
      flash[:error] = 'Session has become stale. Please log in again.'
      redirect_to new_session_path
    when current_session.nil? then
      flash[:error] = 'Login required!'
      redirect_to new_session_path
    when current_session && flash[:expiration] && flash[:expiration] > Time.now then
      reset_timeout
#    else
#      close_session_after_timeout()
#      flash[:error] = 'Session timed out...please login...'
#      redirect_to new_session_path
    end
  end

  def authenticate
    authenticate_or_request_with_http_basic do |user_name, password|
        user_name == 'kevin' && password == 'Troika3.' ||
        user_name = 'lewis' && password = 'Nowisthetime'
    end
  end
  #
  # General Utilities
  #
  def render_js(&blk)
    raise ArgumentError, 'No block given' if blk.nil?
    respond_to do |format|
      format.js do
        render :update do |page|
          yield page
        end
      end
      format.html do
        raise 'Expecting Ajax Request got HTTP'
      end
      format.xml do
        raise 'Expecting Ajax Request got XML request'
      end
    end
  end
end
