require "test_helper"

class GadgetsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get gadgets_index_url
    assert_response :success
  end

  test "should get new" do
    get gadgets_new_url
    assert_response :success
  end

  test "should get show" do
    get gadgets_show_url
    assert_response :success
  end
end
