require "test_helper"

class GalleriesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get galleries_new_url
    assert_response :success
  end

  test "should get show" do
    get galleries_show_url
    assert_response :success
  end

  test "should get index" do
    get galleries_index_url
    assert_response :success
  end

  test "should get create" do
    get galleries_create_url
    assert_response :success
  end
end
