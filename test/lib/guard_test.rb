require "helper"
require "rack/test"
require "guard"

class GuardTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Guard.new(ping, system_env)
  end

  def test_stops_missing_users
    authorize "missing", "missing"

    get "/"

    assert_equal 401, last_response.status
  end

  def test_stops_users_with_wrong_password
    batman = FactoryGirl.create(:user, :batman)
    authorize batman.name, "wrong"

    get "/"

    assert_equal 401, last_response.status
  end

  def test_stops_system_admin_with_wrong_password
    authorize system_env["PROCTOR_ADMIN_USERNAME"], "wrong"

    get "/"

    assert_equal 401, last_response.status
  end

  def test_allows_users_with_correct_password
    batman = FactoryGirl.create(:user, :batman)
    authorize batman.name, batman.password

    get "/"

    assert_equal 200, last_response.status
    assert_equal batman.name, last_response.body
  end

  def test_allows_system_admin
    authorize system_env["PROCTOR_ADMIN_USERNAME"],
              system_env["PROCTOR_ADMIN_PASSWORD"]

    get "/"

    assert_equal 200, last_response.status
    assert_equal system_env["PROCTOR_ADMIN_USERNAME"], last_response.body
  end

  private

  def ping
    proc do |env|
      [200, {}, [env["guard.user"].name]]
    end
  end

  def system_env
    @system_env ||= {
      "PROCTOR_ADMIN_USERNAME" => "guardian",
      "PROCTOR_ADMIN_PASSWORD" => "secret",
    }
  end
end
