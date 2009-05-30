require File.dirname(__FILE__) + '/../test_helper'
require 'sectors_controller'

# Re-raise errors caught by the controller.
class SectorsController; def rescue_action(e) raise e end; end

class SectorsControllerTest < Test::Unit::TestCase
  fixtures :sectors

  def setup
    @controller = SectorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:sectors)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_sector
    old_count = Sector.count
    post :create, :sector => { }
    assert_equal old_count + 1, Sector.count

    assert_redirected_to sector_path(assigns(:sector))
  end

  def test_should_show_sector
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_sector
    put :update, :id => 1, :sector => { }
    assert_redirected_to sector_path(assigns(:sector))
  end

  def test_should_destroy_sector
    old_count = Sector.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Sector.count

    assert_redirected_to sectors_path
  end
end
