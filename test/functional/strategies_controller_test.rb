require File.dirname(__FILE__) + '/../test_helper'
require 'strategies_controller'

# Re-raise errors caught by the controller.
class StrategiesController; def rescue_action(e) raise e end; end

class StrategiesControllerTest < Test::Unit::TestCase
  fixtures :strategies

  def setup
    @controller = StrategiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:strategies)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_strategy
    old_count = Strategy.count
    post :create, :strategy => { }
    assert_equal old_count + 1, Strategy.count

    assert_redirected_to strategy_path(assigns(:strategy))
  end

  def test_should_show_strategy
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_strategy
    put :update, :id => 1, :strategy => { }
    assert_redirected_to strategy_path(assigns(:strategy))
  end

  def test_should_destroy_strategy
    old_count = Strategy.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Strategy.count

    assert_redirected_to strategies_path
  end
end
