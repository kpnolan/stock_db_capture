require File.dirname(__FILE__) + '/../test_helper'
require 'listing_categories_controller'

# Re-raise errors caught by the controller.
class ListingCategoriesController; def rescue_action(e) raise e end; end

class ListingCategoriesControllerTest < Test::Unit::TestCase
  fixtures :listing_categories

  def setup
    @controller = ListingCategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:listing_categories)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_listing_category
    old_count = ListingCategory.count
    post :create, :listing_category => { }
    assert_equal old_count + 1, ListingCategory.count

    assert_redirected_to listing_category_path(assigns(:listing_category))
  end

  def test_should_show_listing_category
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_listing_category
    put :update, :id => 1, :listing_category => { }
    assert_redirected_to listing_category_path(assigns(:listing_category))
  end

  def test_should_destroy_listing_category
    old_count = ListingCategory.count
    delete :destroy, :id => 1
    assert_equal old_count-1, ListingCategory.count

    assert_redirected_to listing_categories_path
  end
end
