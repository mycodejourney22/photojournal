require "test_helper"

class PhotoShootsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get photo_shoots_new_url
    assert_response :success
  end

  test "should get create" do
    get photo_shoots_create_url
    assert_response :success
  end
end
