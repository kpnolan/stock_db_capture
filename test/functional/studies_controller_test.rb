require File.dirname(__FILE__) + '/../test_helper'
require 'studies_controller'

# Re-raise errors caught by the controller.
class StudiesController; def rescue_action(e) raise e end; end

class StudiesControllerTest < Test::Unit::TestCase
  fixtures :studies

  def setup
    @controller = StudiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:studies)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_study
    old_count = Study.count
    post :create, :study => { }
    assert_equal old_count + 1, Study.count

    assert_redirected_to study_path(assigns(:study))
  end

  def test_should_show_study
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_study
    put :update, :id => 1, :study => { }
    assert_redirected_to study_path(assigns(:study))
  end

  def test_should_destroy_study
    old_count = Study.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Study.count

    assert_redirected_to studies_path
  end
end
