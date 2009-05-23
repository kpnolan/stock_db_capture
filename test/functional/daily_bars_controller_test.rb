require File.dirname(__FILE__) + '/../test_helper'
require 'daily_bars_controller'

# Re-raise errors caught by the controller.
class DailyBarsController; def rescue_action(e) raise e end; end

class DailyBarsControllerTest < Test::Unit::TestCase
  fixtures :daily_bars

  def setup
    @controller = DailyBarsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:daily_bars)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_daily_bar
    old_count = DailyBar.count
    post :create, :daily_bar => { }
    assert_equal old_count + 1, DailyBar.count

    assert_redirected_to daily_bar_path(assigns(:daily_bar))
  end

  def test_should_show_daily_bar
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_daily_bar
    put :update, :id => 1, :daily_bar => { }
    assert_redirected_to daily_bar_path(assigns(:daily_bar))
  end

  def test_should_destroy_daily_bar
    old_count = DailyBar.count
    delete :destroy, :id => 1
    assert_equal old_count-1, DailyBar.count

    assert_redirected_to daily_bars_path
  end
end
