require "helper"
require "set"
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

  def test_thread_safety
    guard = Guard.new(cross_requests_checker, system_env)
    guard.user_finder = fake_user_finder

    requests = [check_request("batman"), check_request("guardian")]
    response_codes = Set.new

    30.times do
      threads = 5.times.map do
        Thread.new do
          request = requests.sample.dup
          status, _, _ = guard.call(request)

          response_codes << status
        end
      end
      threads.map(&:join)
    end

    assert !response_codes.include?(500),
           "Expected not to cross users between calls"
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
      "PROCTOR_ADMIN_PASSWORD" => "guardian",
    }
  end

  def cross_requests_checker
    proc do |env|
      expected = env["PATH_INFO"].split("/").last
      actual   = env["guard.user"].name if env["guard.user"]

      status = expected == actual ? 200 : 500

      [status, {}, ""]
    end
  end

  def check_request(name)
    encoded_login = ["#{name}:#{name}"].pack("m*")
    {
      "HTTP_AUTHORIZATION" => "Basic #{encoded_login}",
      "PATH_INFO"          => "/#{name}",
    }
  end

  def fake_user_finder
    Class.new do
      def self.find_by(options = {})
        if options[:name] == "batman"
          User.new(:name => options[:name], :password => "batman")
        end
      end
    end
  end
end
