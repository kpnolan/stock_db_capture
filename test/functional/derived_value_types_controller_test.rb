require File.dirname(__FILE__) + '/../test_helper'
require 'derived_value_types_controller'

# Re-raise errors caught by the controller.
class DerivedValueTypesController; def rescue_action(e) raise e end; end

class DerivedValueTypesControllerTest < Test::Unit::TestCase
  fixtures :derived_value_types

  def setup
    @controller = DerivedValueTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:derived_value_types)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_derived_value_type
    old_count = DerivedValueType.count
    post :create, :derived_value_type => { }
    assert_equal old_count + 1, DerivedValueType.count

    assert_redirected_to derived_value_type_path(assigns(:derived_value_type))
  end

  def test_should_show_derived_value_type
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_derived_value_type
    put :update, :id => 1, :derived_value_type => { }
    assert_redirected_to derived_value_type_path(assigns(:derived_value_type))
  end

  def test_should_destroy_derived_value_type
    old_count = DerivedValueType.count
    delete :destroy, :id => 1
    assert_equal old_count-1, DerivedValueType.count

    assert_redirected_to derived_value_types_path
  end
end
