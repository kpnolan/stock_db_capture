require File.dirname(__FILE__) + '/../test_helper'
require 'contract_types_controller'

# Re-raise errors caught by the controller.
class ContractTypesController; def rescue_action(e) raise e end; end

class ContractTypesControllerTest < Test::Unit::TestCase
  fixtures :contract_types

  def setup
    @controller = ContractTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:contract_types)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_contract_type
    old_count = ContractType.count
    post :create, :contract_type => { }
    assert_equal old_count + 1, ContractType.count

    assert_redirected_to contract_type_path(assigns(:contract_type))
  end

  def test_should_show_contract_type
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_contract_type
    put :update, :id => 1, :contract_type => { }
    assert_redirected_to contract_type_path(assigns(:contract_type))
  end

  def test_should_destroy_contract_type
    old_count = ContractType.count
    delete :destroy, :id => 1
    assert_equal old_count-1, ContractType.count

    assert_redirected_to contract_types_path
  end
end
