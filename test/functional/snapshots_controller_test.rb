require File.dirname(__FILE__) + '/../test_helper'
require 'snapshots_controller'

# Re-raise errors caught by the controller.
class SnapshotsController; def rescue_action(e) raise e end; end

class SnapshotsControllerTest < Test::Unit::TestCase
  fixtures :snapshots

  def setup
    @controller = SnapshotsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:snapshots)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_snapshot
    old_count = Snapshot.count
    post :create, :snapshot => { }
    assert_equal old_count + 1, Snapshot.count

    assert_redirected_to snapshot_path(assigns(:snapshot))
  end

  def test_should_show_snapshot
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_snapshot
    put :update, :id => 1, :snapshot => { }
    assert_redirected_to snapshot_path(assigns(:snapshot))
  end

  def test_should_destroy_snapshot
    old_count = Snapshot.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Snapshot.count

    assert_redirected_to snapshots_path
  end
end
