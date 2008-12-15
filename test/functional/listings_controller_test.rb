require File.dirname(__FILE__) + '/../test_helper'
require 'listings_controller'

# Re-raise errors caught by the controller.
class ListingsController; def rescue_action(e) raise e end; end

class ListingsControllerTest < Test::Unit::TestCase
  fixtures :listings

  def setup
    @controller = ListingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:listings)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_listing
    old_count = Listing.count
    post :create, :listing => { }
    assert_equal old_count + 1, Listing.count

    assert_redirected_to listing_path(assigns(:listing))
  end

  def test_should_show_listing
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_listing
    put :update, :id => 1, :listing => { }
    assert_redirected_to listing_path(assigns(:listing))
  end

  def test_should_destroy_listing
    old_count = Listing.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Listing.count

    assert_redirected_to listings_path
  end
end
