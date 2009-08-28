require File.dirname(__FILE__) + '/../test_helper'
require 'exit_strategies_controller'

# Re-raise errors caught by the controller.
class ExitStrategiesController; def rescue_action(e) raise e end; end

class ExitStrategiesControllerTest < Test::Unit::TestCase
  fixtures :exit_strategies

  def setup
    @controller = ExitStrategiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:exit_strategies)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_exit_strategy
    old_count = ExitStrategy.count
    post :create, :exit_strategy => { }
    assert_equal old_count + 1, ExitStrategy.count

    assert_redirected_to exit_strategy_path(assigns(:exit_strategy))
  end

  def test_should_show_exit_strategy
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_exit_strategy
    put :update, :id => 1, :exit_strategy => { }
    assert_redirected_to exit_strategy_path(assigns(:exit_strategy))
  end

  def test_should_destroy_exit_strategy
    old_count = ExitStrategy.count
    delete :destroy, :id => 1
    assert_equal old_count-1, ExitStrategy.count

    assert_redirected_to exit_strategies_path
  end
end
