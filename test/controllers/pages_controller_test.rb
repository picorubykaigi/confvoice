require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "ホームにデフォルトOGP画像とX向けmetaを表示すること" do
    get root_path

    default_og_image_url = "http://www.example.com/ogp.png"

    assert_response :success
    assert_select "meta[property='og:title'][content=?]", "ConfVoice"
    assert_select "meta[property='og:image'][content=?]", default_og_image_url
    assert_select "meta[property='og:image:secure_url'][content=?]", default_og_image_url
    assert_select "meta[property='og:image:type'][content='image/png']"
    assert_select "meta[property='og:image:width'][content='1280']"
    assert_select "meta[property='og:image:height'][content='670']"
    assert_select "meta[property='og:image:alt'][content=?]", "ConfVoice のOGP画像"
    assert_select "meta[name='twitter:card'][content='summary_large_image']"
    assert_select "meta[name='twitter:image'][content=?]", default_og_image_url
    assert_select "meta[name='twitter:image:alt'][content=?]", "ConfVoice のOGP画像"
  end

  test "トップをConfVoiceの入口として表示すること" do
    get root_path

    assert_response :success
    assert_select "header a[href=?]", root_path, text: "ConfVoice"
    assert_select "h1", "ConfVoice"
    assert_select "main img", count: 0
    assert_select "main time[datetime='2026-10-31']", count: 0
    assert_no_match "浅草橋ヒューリックホール", response.body
  end

  test "日本語をデフォルト表示にし管理画面導線を維持すること" do
    user = create(:user, :organizer)

    sign_in_as(user)
    get root_path

    assert_equal :ja, I18n.default_locale
    assert_select "html[lang=ja]"
    assert_select "a[href=?]", conferences_path, text: /管理画面へ/
    assert_select "header a[href=?]", conferences_path, text: "カンファレンス"
    assert_select ".locale-switch", count: 0
    assert_select "a[hreflang]", count: 0
  end

  test "以前の英語ロケール指定が残っていても日本語で表示すること" do
    cookies[:locale] = "en"

    I18n.with_locale(:en) do
      get root_path(locale: :en)
    end

    assert_response :success
    assert_select "h1", "ConfVoice"
    assert_select "html[lang=ja]"
    assert_select "h2", "カンファレンスを選ぶ"
  end

  test "公開済みカンファレンスへの導線を表示すること" do
    conference = create(:conference, name: "PicoRubyKaigi 2026 Assemble")
    draft = create(:conference, published: false)

    get root_path

    assert_response :success
    assert_select "h1", "ConfVoice"
    assert_select "a[href='https://picorubykaigi.org/']", text: "公式サイト"
    assert_select "a[href=?]", public_conference_path(conference), text: /トークを見る/
    assert_select "a[href=?]", public_conference_path(draft), count: 0
    assert_select "a[href='#main-content']", text: "本文へ移動"
  end
end
