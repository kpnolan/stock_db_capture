require File.dirname(__FILE__) + '/../test_helper'
require 'entry_strategies_controller'

# Re-raise errors caught by the controller.
class EntryStrategiesController; def rescue_action(e) raise e end; end

class EntryStrategiesControllerTest < Test::Unit::TestCase
  fixtures :entry_strategies

  def setup
    @controller = EntryStrategiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:entry_strategies)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_entry_strategy
    old_count = EntryStrategy.count
    post :create, :entry_strategy => { }
    assert_equal old_count + 1, EntryStrategy.count

    assert_redirected_to entry_strategy_path(assigns(:entry_strategy))
  end

  def test_should_show_entry_strategy
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_entry_strategy
    put :update, :id => 1, :entry_strategy => { }
    assert_redirected_to entry_strategy_path(assigns(:entry_strategy))
  end

  def test_should_destroy_entry_strategy
    old_count = EntryStrategy.count
    delete :destroy, :id => 1
    assert_equal old_count-1, EntryStrategy.count

    assert_redirected_to entry_strategies_path
  end
end
