require "test_helper"

class PublicFeedbackFlowTest < ActionDispatch::IntegrationTest
  test "聴衆が感想を投稿できること" do
    session = create(:session, feedback_open: true)

    assert_equal "/t/#{session.id}", public_feedback_path(session.id)

    get public_feedback_path(session.id)
    assert_response :success
    assert_select "form[action=?]", "/t/#{session.id}"
    assert_select "a[href=?]", public_conference_path(session.conference), text: "トーク一覧へ"
    assert_select "form[data-controller=?][data-feedback-draft-key-value=?]", "feedback-draft", "feedback-draft:#{session.conference.slug}:#{session.slug}"
    assert_select "input[name=?][data-feedback-draft-target=?]", "feedback[respondent_name]", "field"
    assert_select "textarea[name=?][data-feedback-draft-target=?]", "feedback[body]", "field"
    assert_select "input[name=?]", "feedback[rating]", count: 0
    assert_select "html[lang=ja]"
    assert_select "label[for=feedback_respondent_name]", "お名前"
    assert_select "input[type=submit][value=?]", "感想を送る"

    assert_difference "Feedback.count", 1 do
      post public_feedback_path(session.id), params: {
        feedback: { respondent_name: "参加者 太郎", body: "とても良かった！" }
      }
    end
    assert_redirected_to "/t/#{session.id}/thanks"
    assert_equal "参加者 太郎", Feedback.last.respondent_name
    assert_nil Feedback.last.rating
    follow_redirect!
    assert_select "h1", "感想を送信しました"
  end

  test "入力不足のエラーを日本語で表示すること" do
    session = create(:session, feedback_open: true)

    assert_no_difference "Feedback.count" do
      post public_feedback_path(session.id), params: {
        feedback: { respondent_name: "", body: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "お名前を入力してください"
    assert_includes response.body, "感想を入力してください"
  end

  test "日本語の名前とタイトルでも投稿URLはトークIDだけになること" do
    conference = create(:conference, name: "東京Ruby会議", slug: nil)
    session = create(:session, conference: conference, title: "パフォーマンスチューニング", slug: nil)

    assert_equal "/t/#{session.id}", public_feedback_path(session.id)
    get public_feedback_path(session.id)

    assert_response :success
    assert_select "h1", session.title
  end

  test "非公開カンファレンスのトークはIDがわかっても閲覧や投稿ができないこと" do
    session = create(:session, conference: create(:conference, published: false))

    get public_feedback_path(session.id)
    assert_response :not_found

    get public_feedback_thanks_path(session.id)
    assert_response :not_found

    assert_no_difference "Feedback.count" do
      post public_feedback_path(session.id), params: {
        feedback: { respondent_name: "参加者", body: "感想" }
      }
    end
    assert_response :not_found
  end

  test "存在しないIDや数字以外を含むIDは見つからないこと" do
    get "/t/0"
    assert_response :not_found

    session = create(:session)
    get "/t/#{session.id}invalid"
    assert_response :not_found
  end

  test "タイトル由来の古い投稿URLは使わないこと" do
    session = create(:session)

    get "/#{session.conference.slug}/talks/#{ERB::Util.url_encode(session.slug)}"

    assert_response :not_found
  end

  test "感想受付終了セッションには投稿できないこと" do
    session = create(:session, feedback_open: false)

    get public_feedback_path(session.id)

    assert_response :forbidden
    assert_select "a[href=?]", public_conference_path(session.conference), text: "トーク一覧へ"

    assert_no_difference "Feedback.count" do
      post public_feedback_path(session.id), params: {
        feedback: { respondent_name: "参加者", body: "感想" }
      }
    end
    assert_response :forbidden
  end
end
