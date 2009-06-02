require File.dirname(__FILE__) + '/../test_helper'
require 'intra_snapshots_controller'

# Re-raise errors caught by the controller.
class IntraSnapshotsController; def rescue_action(e) raise e end; end

class IntraSnapshotsControllerTest < Test::Unit::TestCase
  fixtures :intra_snapshots

  def setup
    @controller = IntraSnapshotsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:intra_snapshots)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_intra_snapshot
    old_count = IntraSnapshot.count
    post :create, :intra_snapshot => { }
    assert_equal old_count + 1, IntraSnapshot.count

    assert_redirected_to intra_snapshot_path(assigns(:intra_snapshot))
  end

  def test_should_show_intra_snapshot
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_intra_snapshot
    put :update, :id => 1, :intra_snapshot => { }
    assert_redirected_to intra_snapshot_path(assigns(:intra_snapshot))
  end

  def test_should_destroy_intra_snapshot
    old_count = IntraSnapshot.count
    delete :destroy, :id => 1
    assert_equal old_count-1, IntraSnapshot.count

    assert_redirected_to intra_snapshots_path
  end
end
