require File.dirname(__FILE__) + '/../test_helper'
require 'trigger_strategies_controller'

# Re-raise errors caught by the controller.
class TriggerStrategiesController; def rescue_action(e) raise e end; end

class TriggerStrategiesControllerTest < Test::Unit::TestCase
  fixtures :trigger_strategies

  def setup
    @controller = TriggerStrategiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:trigger_strategies)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_trigger_strategy
    old_count = TriggerStrategy.count
    post :create, :trigger_strategy => { }
    assert_equal old_count + 1, TriggerStrategy.count

    assert_redirected_to trigger_strategy_path(assigns(:trigger_strategy))
  end

  def test_should_show_trigger_strategy
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_trigger_strategy
    put :update, :id => 1, :trigger_strategy => { }
    assert_redirected_to trigger_strategy_path(assigns(:trigger_strategy))
  end

  def test_should_destroy_trigger_strategy
    old_count = TriggerStrategy.count
    delete :destroy, :id => 1
    assert_equal old_count-1, TriggerStrategy.count

    assert_redirected_to trigger_strategies_path
  end
end
