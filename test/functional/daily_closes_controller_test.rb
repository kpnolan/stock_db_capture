require File.dirname(__FILE__) + '/../test_helper'
require 'daily_closes_controller'

# Re-raise errors caught by the controller.
class DailyClosesController; def rescue_action(e) raise e end; end

class DailyClosesControllerTest < Test::Unit::TestCase
  fixtures :daily_closes

  def setup
    @controller = DailyClosesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:daily_closes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_daily_close
    old_count = DailyClose.count
    post :create, :daily_close => { }
    assert_equal old_count + 1, DailyClose.count

    assert_redirected_to daily_close_path(assigns(:daily_close))
  end

  def test_should_show_daily_close
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_daily_close
    put :update, :id => 1, :daily_close => { }
    assert_redirected_to daily_close_path(assigns(:daily_close))
  end

  def test_should_destroy_daily_close
    old_count = DailyClose.count
    delete :destroy, :id => 1
    assert_equal old_count-1, DailyClose.count

    assert_redirected_to daily_closes_path
  end
end
