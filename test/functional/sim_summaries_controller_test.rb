require File.dirname(__FILE__) + '/../test_helper'
require 'sim_summaries_controller'

# Re-raise errors caught by the controller.
class SimSummariesController; def rescue_action(e) raise e end; end

class SimSummariesControllerTest < Test::Unit::TestCase
  fixtures :sim_summaries

  def setup
    @controller = SimSummariesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:sim_summaries)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_sim_summary
    old_count = SimSummary.count
    post :create, :sim_summary => { }
    assert_equal old_count + 1, SimSummary.count

    assert_redirected_to sim_summary_path(assigns(:sim_summary))
  end

  def test_should_show_sim_summary
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_sim_summary
    put :update, :id => 1, :sim_summary => { }
    assert_redirected_to sim_summary_path(assigns(:sim_summary))
  end

  def test_should_destroy_sim_summary
    old_count = SimSummary.count
    delete :destroy, :id => 1
    assert_equal old_count-1, SimSummary.count

    assert_redirected_to sim_summaries_path
  end
end
