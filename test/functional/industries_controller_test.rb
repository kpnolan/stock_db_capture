require File.dirname(__FILE__) + '/../test_helper'
require 'industries_controller'

# Re-raise errors caught by the controller.
class IndustriesController; def rescue_action(e) raise e end; end

class IndustriesControllerTest < Test::Unit::TestCase
  fixtures :industries

  def setup
    @controller = IndustriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:industries)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_industry
    old_count = Industry.count
    post :create, :industry => { }
    assert_equal old_count + 1, Industry.count

    assert_redirected_to industry_path(assigns(:industry))
  end

  def test_should_show_industry
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_industry
    put :update, :id => 1, :industry => { }
    assert_redirected_to industry_path(assigns(:industry))
  end

  def test_should_destroy_industry
    old_count = Industry.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Industry.count

    assert_redirected_to industries_path
  end
end
