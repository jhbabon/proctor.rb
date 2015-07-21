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

  def test_delete_existing_user
    User.create(:name => "joker")

    delete "/users/joker"

    assert_status 204
    assert_nil User.find_by(:name => "joker")
  end

  def test_delete_missing_user
    delete "/users/clayface"

    assert_status 404
  end

  def test_create_pubkey
    user = User.create(:name => "batman")
    before = user.pubkeys.count

    key = fixture_file("id_rsa.pub").read
    payload = {
      "title" => "testkey",
      "key"   => key,
    }
    post "/users/batman/pubkeys", to_json(payload)

    assert_status 201
    assert_match(
      /\/users\/batman\/pubkeys\/testkey\z/,
      last_response.headers["Location"]
    )

    after = user.pubkeys.count
    assert_equal before + 1, after
  end

  def test_update_pubkey
    key = fixture_file("id_rsa.pub").read
    user = User.create(:name => "batman")
    user.pubkeys.create(:title => "batkey", :key => key)

    payload = { "key" => fixture_file("id_rsa_v2.pub").read }

    patch "/users/batman/pubkeys/batkey", to_json(payload)

    assert_status 200
  end

  def test_update_missing_key
    User.create(:name => "batman")
    payload = { "key" => fixture_file("id_rsa_v2.pub").read }

    patch "/users/batman/pubkeys/batkey", to_json(payload)

    assert_status 404
  end

  def test_get_one_user_pubkey
    key = fixture_file("id_rsa.pub").read
    user = User.create(:name => "batman")
    user.pubkeys.create(:title => "batkey", :key => key)

    get "/users/batman/pubkeys/batkey"

    actual = parsed_response

    assert_status 200
    assert_equal "batkey", actual["title"]
    assert_equal key, actual["key"]
  end

  def test_get_missing_pubkey
    User.create(:name => "batman")
    get "/users/batman/pubkeys/batkey"

    assert_status 404
  end

  def test_get_user_pubkeys
    user = User.create(:name => "batman")

    key_b = fixture_file("id_rsa_v2.pub").read
    key_a = fixture_file("id_rsa.pub").read
    user.pubkeys.create(:title => "key_b", :key => key_b)
    user.pubkeys.create(:title => "key_a", :key => key_a)

    get "/users/batman/pubkeys"

    actual = parsed_response

    assert_status 200
    assert_equal 2, actual.size
    assert_equal "key_a", actual.first["title"]
    assert_equal key_a, actual.first["key"]
    assert_equal "key_b", actual.last["title"]
    assert_equal key_b, actual.last["key"]
  end

  def test_delete_user_pubkey
    key = fixture_file("id_rsa.pub").read
    user = User.create(:name => "batman")
    user.pubkeys.create(:title => "batkey", :key => key)

    delete "/users/batman/pubkeys/batkey"

    assert_status 204
    assert_nil Pubkey.find_by(:title => "batkey")
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
