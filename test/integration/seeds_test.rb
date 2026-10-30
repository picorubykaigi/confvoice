require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  setup do
    @original_seed_settings = ENV.to_h.slice("ALLOW_PRODUCTION_SEEDS", "CONFVOICE_SEED_PASSWORD")
    ENV.delete("ALLOW_PRODUCTION_SEEDS")
    ENV.delete("CONFVOICE_SEED_PASSWORD")
    assert_equal "test", ActiveRecord::Base.connection_db_config.env_name
  end

  teardown do
    %w[ALLOW_PRODUCTION_SEEDS CONFVOICE_SEED_PASSWORD].each do |key|
      ENV[key] = @original_seed_settings[key]
    end
  end

  test "production database preparation skips demo seeds while development keeps them" do
    databases = ActiveRecord::DatabaseConfigurations.new(Rails.application.config.database_configuration)

    assert_not databases.configs_for(env_name: "production").any?(&:seeds?)
    assert databases.configs_for(env_name: "development", name: "primary").seeds?
  end

  test "production seeds require explicit opt in" do
    ENV["CONFVOICE_SEED_PASSWORD"] = "private-seed-password-for-test"

    assert_no_changes -> { User.count } do
      capture_io do
        error = assert_raises(SystemExit) { run_seeds("production") }
        assert_match "ALLOW_PRODUCTION_SEEDS", error.message
      end
    end
  end

  [ nil, "", "   ", "confvoice-local-password" ].each do |password|
    test "production seeds reject unsafe password #{password.inspect}" do
      ENV["ALLOW_PRODUCTION_SEEDS"] = "true"
      ENV["CONFVOICE_SEED_PASSWORD"] = password

      assert_no_changes -> { User.count } do
        capture_io do
          error = assert_raises(SystemExit) { run_seeds("production") }
          assert_match "CONFVOICE_SEED_PASSWORD", error.message
        end
      end
    end
  end

  test "production seeds use a private password without printing it" do
    ENV["ALLOW_PRODUCTION_SEEDS"] = "true"
    ENV["CONFVOICE_SEED_PASSWORD"] = "private-seed-password-for-test"

    output = capture_io { run_seeds("production") }.join

    assert User.find_by!(email_address: "admin@example.com").authenticate(ENV.fetch("CONFVOICE_SEED_PASSWORD"))
    assert_no_match ENV.fetch("CONFVOICE_SEED_PASSWORD"), output
  end

  test "local seeds keep existing passwords and do not print the default password" do
    user = create(:user, email_address: "admin@example.com")
    password_digest = user.password_digest

    output = capture_io { run_seeds("test") }.join

    assert_equal password_digest, user.reload.password_digest
    assert User.find_by!(email_address: "organizer@example.com").authenticate("confvoice-local-password")
    assert_no_match "confvoice-local-password", output
  end

  test "production seeds do not elevate an existing account to administrator" do
    user = create(:user, :organizer, email_address: "admin@example.com")
    password_digest = user.password_digest
    ENV["ALLOW_PRODUCTION_SEEDS"] = "true"
    ENV["CONFVOICE_SEED_PASSWORD"] = "private-seed-password-for-test"

    capture_io { run_seeds("production") }

    assert_equal "organizer", user.reload.role
    assert_equal password_digest, user.password_digest
  end

  private

  def run_seeds(environment)
    # Scope the environment override to seeds; database and Cable stay in test.
    context = Module.new
    context.const_set(:Rails, Struct.new(:env).new(environment.inquiry))
    path = Rails.root.join("db/seeds.rb")
    context.module_eval(path.read, path.to_s)
  end
end
