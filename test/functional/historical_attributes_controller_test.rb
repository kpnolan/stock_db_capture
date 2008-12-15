require File.dirname(__FILE__) + '/../test_helper'
require 'historical_attributes_controller'

# Re-raise errors caught by the controller.
class HistoricalAttributesController; def rescue_action(e) raise e end; end

class HistoricalAttributesControllerTest < Test::Unit::TestCase
  fixtures :historical_attributes

  def setup
    @controller = HistoricalAttributesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:historical_attributes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_historical_attribute
    old_count = HistoricalAttribute.count
    post :create, :historical_attribute => { }
    assert_equal old_count + 1, HistoricalAttribute.count

    assert_redirected_to historical_attribute_path(assigns(:historical_attribute))
  end

  def test_should_show_historical_attribute
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_historical_attribute
    put :update, :id => 1, :historical_attribute => { }
    assert_redirected_to historical_attribute_path(assigns(:historical_attribute))
  end

  def test_should_destroy_historical_attribute
    old_count = HistoricalAttribute.count
    delete :destroy, :id => 1
    assert_equal old_count-1, HistoricalAttribute.count

    assert_redirected_to historical_attributes_path
  end
end
