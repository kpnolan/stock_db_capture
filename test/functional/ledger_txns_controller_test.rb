require File.dirname(__FILE__) + '/../test_helper'
require 'ledger_txns_controller'

# Re-raise errors caught by the controller.
class LedgerTxnsController; def rescue_action(e) raise e end; end

class LedgerTxnsControllerTest < Test::Unit::TestCase
  fixtures :ledger_txns

  def setup
    @controller = LedgerTxnsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:ledger_txns)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_ledger_txn
    old_count = LedgerTxn.count
    post :create, :ledger_txn => { }
    assert_equal old_count + 1, LedgerTxn.count

    assert_redirected_to ledger_txn_path(assigns(:ledger_txn))
  end

  def test_should_show_ledger_txn
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_ledger_txn
    put :update, :id => 1, :ledger_txn => { }
    assert_redirected_to ledger_txn_path(assigns(:ledger_txn))
  end

  def test_should_destroy_ledger_txn
    old_count = LedgerTxn.count
    delete :destroy, :id => 1
    assert_equal old_count-1, LedgerTxn.count

    assert_redirected_to ledger_txns_path
  end
end
