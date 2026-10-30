require "test_helper"

class Manage::MembershipsControllerTest < ActionDispatch::IntegrationTest
  test "権限の選択肢を日本語で表示し送信値を維持すること" do
    admin = create(:user, :admin)
    conference = create(:conference)
    sign_in_as(admin)

    get conference_manage_memberships_path(conference)
    assert_response :success
    assert_select "option[value=organizer]", "主催者"
    assert_select "option[value=speaker]", "登壇者"

    get new_admin_user_path
    assert_response :success
    assert_select "option[value=admin]", "管理者"
    assert_select "option[value=organizer]", "主催者"
    assert_select "option[value=audience]", "参加者"
  end

  test "Organizer は speaker メンバーを追加できること" do
    organizer = create(:user, :organizer)
    conference = create(:conference)
    create(:conference_membership, user: organizer, conference: conference, role: :organizer)

    sign_in_as(organizer)

    assert_difference "ConferenceMembership.count", 1 do
      post conference_manage_memberships_path(conference), params: {
        conference_membership: {
          role: "speaker",
          email_address: "speaker-new@example.com",
          name: "Speaker New"
        }
      }
    end

    assert_redirected_to conference_manage_memberships_path(conference)
  end
end
