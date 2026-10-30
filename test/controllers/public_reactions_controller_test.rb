require "test_helper"

class PublicReactionsControllerTest < ActionDispatch::IntegrationTest
  test "聴衆がリアクションできること" do
    session = create(:session)

    assert_difference "Reaction.count", 1 do
      post public_reactions_path(session.id), params: {
        reaction: { kind: "fire" }
      }
    end

    assert_redirected_to "/t/#{session.id}"
  end

  test "同じリアクションは重複送信できないこと" do
    session = create(:session)

    post public_reactions_path(session.id), params: { reaction: { kind: "idea" } }

    assert_no_difference "Reaction.count" do
      post public_reactions_path(session.id), params: { reaction: { kind: "idea" } }
    end
  end

  test "非公開カンファレンスのトークにはIDがわかってもリアクションできないこと" do
    session = create(:session, conference: create(:conference, published: false))

    assert_no_difference "Reaction.count" do
      post public_reactions_path(session.id), params: { reaction: { kind: "idea" } }
    end

    assert_response :not_found
  end
end
