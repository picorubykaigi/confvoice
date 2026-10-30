require "test_helper"

class LightThemeRenderingTest < ActionDispatch::IntegrationTest
  test "application layout always uses the light theme without a toggle" do
    get root_path

    assert_response :success
    assert_select "header"
    assert_select "button[data-controller='theme']", count: 0
    assert_select "html.dark", count: 0
    assert_no_match "confvoice-theme", response.body
  end

  test "public layout always uses the light theme and keeps the talk navigation" do
    conference = create(:conference)

    get public_conference_path(conference)

    assert_response :success
    assert_select "header"
    assert_select "header a[href=?]", public_conference_path(conference), text: conference.name
    assert_select "header a[href=?]", new_session_path, count: 0
    assert_select "header a[href=?]", new_registration_path, count: 0
    assert_select "button[data-controller='theme']", count: 0
    assert_select "html.dark", count: 0
    assert_no_match "confvoice-theme", response.body
  end
end
