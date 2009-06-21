require File.dirname(__FILE__) + '/../test_helper'
require 'indicators_controller'

# Re-raise errors caught by the controller.
class IndicatorsController; def rescue_action(e) raise e end; end

class IndicatorsControllerTest < Test::Unit::TestCase
  fixtures :indicators

  def setup
    @controller = IndicatorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:indicators)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_indicator
    old_count = Indicator.count
    post :create, :indicator => { }
    assert_equal old_count + 1, Indicator.count

    assert_redirected_to indicator_path(assigns(:indicator))
  end

  def test_should_show_indicator
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_indicator
    put :update, :id => 1, :indicator => { }
    assert_redirected_to indicator_path(assigns(:indicator))
  end

  def test_should_destroy_indicator
    old_count = Indicator.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Indicator.count

    assert_redirected_to indicators_path
  end
end
