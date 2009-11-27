require File.dirname(__FILE__) + '/../test_helper'
require 'sim_jobs_controller'

# Re-raise errors caught by the controller.
class SimJobsController; def rescue_action(e) raise e end; end

class SimJobsControllerTest < Test::Unit::TestCase
  fixtures :sim_jobs

  def setup
    @controller = SimJobsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:sim_jobs)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_sim_jobs
    old_count = SimJobs.count
    post :create, :sim_jobs => { }
    assert_equal old_count + 1, SimJobs.count

    assert_redirected_to sim_jobs_path(assigns(:sim_jobs))
  end

  def test_should_show_sim_jobs
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_sim_jobs
    put :update, :id => 1, :sim_jobs => { }
    assert_redirected_to sim_jobs_path(assigns(:sim_jobs))
  end

  def test_should_destroy_sim_jobs
    old_count = SimJobs.count
    delete :destroy, :id => 1
    assert_equal old_count-1, SimJobs.count

    assert_redirected_to sim_jobs_path
  end
end
