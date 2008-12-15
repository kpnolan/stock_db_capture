require File.dirname(__FILE__) + '/../test_helper'
require 'aggregations_controller'

# Re-raise errors caught by the controller.
class AggregationsController; def rescue_action(e) raise e end; end

class AggregationsControllerTest < Test::Unit::TestCase
  fixtures :aggregations

  def setup
    @controller = AggregationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:aggregations)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_aggregation
    old_count = Aggregation.count
    post :create, :aggregation => { }
    assert_equal old_count + 1, Aggregation.count

    assert_redirected_to aggregation_path(assigns(:aggregation))
  end

  def test_should_show_aggregation
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_aggregation
    put :update, :id => 1, :aggregation => { }
    assert_redirected_to aggregation_path(assigns(:aggregation))
  end

  def test_should_destroy_aggregation
    old_count = Aggregation.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Aggregation.count

    assert_redirected_to aggregations_path
  end
end
