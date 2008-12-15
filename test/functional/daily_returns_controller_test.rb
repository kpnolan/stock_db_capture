require File.dirname(__FILE__) + '/../test_helper'
require 'daily_returns_controller'

# Re-raise errors caught by the controller.
class DailyReturnsController; def rescue_action(e) raise e end; end

class DailyReturnsControllerTest < Test::Unit::TestCase
  fixtures :daily_returns

  def setup
    @controller = DailyReturnsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:daily_returns)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_daily_return
    old_count = DailyReturn.count
    post :create, :daily_return => { }
    assert_equal old_count + 1, DailyReturn.count

    assert_redirected_to daily_return_path(assigns(:daily_return))
  end

  def test_should_show_daily_return
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_daily_return
    put :update, :id => 1, :daily_return => { }
    assert_redirected_to daily_return_path(assigns(:daily_return))
  end

  def test_should_destroy_daily_return
    old_count = DailyReturn.count
    delete :destroy, :id => 1
    assert_equal old_count-1, DailyReturn.count

    assert_redirected_to daily_returns_path
  end
end
