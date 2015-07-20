require "helper"
require "rack/test"
require "proctor"

class ProctorTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_root
    get "/", {}, "HTTP_CONTENT_TYPE" => "application/json"

    assert_status 200
    assert_equal "Hello world!", last_response.body
  end

  def test_get_users_without_any_user
    User.destroy_all

    get "/users"

    assert_status 200
    assert_predicate parsed_response, :empty?
  end

  def test_get_users_with_existing_users
    2.times do |n|
      User.create(:name => "test-#{n}")
    end

    get "/users"

    actual = parsed_response

    assert_status 200
    assert_equal 2, actual.size
    assert_equal "test-0", actual.first["name"]
    assert_equal "test-1", actual.last["name"]
  end

  def test_get_users_ordered_by_name
    User.create(:name => "conan")
    User.create(:name => "atila")

    get "/users"

    actual = parsed_response

    assert_status 200
    assert_equal 2, actual.size
    assert_equal "atila", actual.first["name"]
    assert_equal "conan", actual.last["name"]
  end

  def test_get_user_with_wrong_name
    get "/users/missing"

    assert_status 404
  end

  def test_get_user_with_existing_name
    User.create(:name => "batman")

    get "/users/batman"

    assert_status 200
    assert_equal parsed_response["name"], "batman"
  end

  def test_create_user
    post "/users", to_json({ "name" => "batman" })

    assert_status 201
    assert_match(/\/users\/batman\z/, last_response.headers["Location"])
  end

  def test_create_user_with_exising_name
    User.create(:name => "batman")

    post "/users", to_json({ "name" => "batman" })

    assert_status 422
  end

  def test_update_missing_user
    patch "/users/robin", to_json({ "name" => "batman" })

    assert_status 404
  end

  def test_update_user
    User.create(:name => "robin")

    patch "/users/robin", to_json({ "name" => "batman" })

    assert_status 200
    assert_match(/\/users\/batman\z/, last_response.headers["Location"])
  end

  def test_update_user_with_existing_name
    User.create(:name => "robin")
    User.create(:name => "batman")

    patch "/users/robin", to_json({ "name" => "batman" })

    assert_status 422
  end

  private

  def assert_status(code)
    assert_equal code, last_response.status
  end

  def parsed_response
    Oj.load last_response.body
  end

  def to_json(payload)
    Oj.dump payload
  end
end
