require "test_helper"
require "rack/mock"

class PublicFeedbackRateLimitTest < ActiveSupport::TestCase
  setup do
    @original_cache_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    @request = Rack::MockRequest.new(Rack::Attack.new(->(_env) { [ 200, {}, [ "OK" ] ] }))
  end

  teardown do
    Rack::Attack.cache.store = @original_cache_store
  end

  test "短いURLでも感想とリアクションは合わせて1分間に5回までに制限されること" do
    freeze_time do
      paths = [ "/t/42", "/t/42/reactions" ]
      5.times do |index|
        assert_equal 200, @request.post(paths[index % 2], "HTTP_COOKIE" => "respondent_token=one").status
      end

      paths.each do |path|
        assert_equal 429, @request.post(path, "HTTP_COOKIE" => "respondent_token=one").status
      end

      assert_equal 200, @request.post("/t/42", "HTTP_COOKIE" => "respondent_token=two").status
      assert_equal 200, @request.get("/t/42", "HTTP_COOKIE" => "respondent_token=one").status
    end
  end
end
